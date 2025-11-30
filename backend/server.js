const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
require('dotenv').config();

// Twilio setup
const twilio = require('twilio');
const twilioClient = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

const smsLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10, // limit each IP to 10 SMS per hour
  message: 'SMS rate limit exceeded. Please try again later.'
});

app.use(limiter);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// API Key authentication middleware
const authenticateApiKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  
  if (!apiKey) {
    return res.status(401).json({ error: 'API key required' });
  }
  
  if (apiKey !== process.env.CLIENT_API_KEY) {
    return res.status(403).json({ error: 'Invalid API key' });
  }
  
  next();
};

// In-memory storage for demo (use database in production)
const smsHistory = [];
const messageStatuses = new Map();

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    services: {
      twilio: !!process.env.TWILIO_ACCOUNT_SID,
      database: true // Replace with actual DB health check
    }
  });
});

// Send SMS endpoint
app.post('/v1/emergency/send-sms', 
  smsLimiter,
  authenticateApiKey,
  [
    body('recipients').isArray().withMessage('Recipients must be an array'),
    body('recipients.*').isMobilePhone().withMessage('Invalid phone number format'),
    body('message').isLength({ min: 1, max: 1600 }).withMessage('Message must be 1-1600 characters'),
    body('provider').optional().isIn(['twilio', 'vonage', 'aws']).withMessage('Invalid provider')
  ],
  async (req, res) => {
    try {
      // Validate request
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation failed',
          details: errors.array()
        });
      }

      const { recipients, message, metadata = {} } = req.body;
      const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

      console.log(`Sending SMS to ${recipients.length} recipients: ${messageId}`);

      // Send SMS via Twilio
      const results = [];
      for (const recipient of recipients) {
        try {
          const twilioMessage = await twilioClient.messages.create({
            body: message,
            from: process.env.TWILIO_FROM_NUMBER,
            to: recipient,
            statusCallback: `${process.env.BASE_URL}/v1/emergency/sms-webhook/${messageId}`
          });

          results.push({
            recipient,
            status: 'sent',
            twilioSid: twilioMessage.sid,
            error: null
          });

          // Store status for tracking
          messageStatuses.set(`${messageId}_${recipient}`, {
            status: 'sent',
            twilioSid: twilioMessage.sid,
            timestamp: new Date()
          });

        } catch (error) {
          console.error(`Failed to send SMS to ${recipient}:`, error.message);
          results.push({
            recipient,
            status: 'failed',
            twilioSid: null,
            error: error.message
          });
        }
      }

      // Store in history
      const smsRecord = {
        id: messageId,
        recipients,
        message,
        timestamp: new Date().toISOString(),
        status: results.every(r => r.status === 'sent') ? 'sent' : 'partial',
        results,
        metadata
      };
      smsHistory.push(smsRecord);

      res.status(201).json({
        message_id: messageId,
        status: smsRecord.status,
        sent_count: results.filter(r => r.status === 'sent').length,
        failed_count: results.filter(r => r.status === 'failed').length,
        results
      });

    } catch (error) {
      console.error('SMS sending error:', error);
      res.status(500).json({
        error: 'Internal server error',
        message: 'Failed to send SMS'
      });
    }
  }
);

// Share location endpoint
app.post('/v1/emergency/share-location',
  smsLimiter,
  authenticateApiKey,
  [
    body('recipients').isArray().withMessage('Recipients must be an array'),
    body('recipients.*').isMobilePhone().withMessage('Invalid phone number format'),
    body('lat').isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude'),
    body('lon').isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude'),
    body('label').optional().isLength({ max: 100 }).withMessage('Label too long')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation failed',
          details: errors.array()
        });
      }

      const { recipients, lat, lon, label = 'Emergency Location' } = req.body;
      const mapLink = `https://maps.google.com/?q=${lat},${lon}`;
      
      let message = `${label}\n\nLocation: ${mapLink}`;
      if (req.body.custom_message) {
        message = `${req.body.custom_message}\n\n${mapLink}`;
      }

      // Reuse the SMS sending logic
      const smsRequest = {
        recipients,
        message,
        metadata: {
          type: 'location_share',
          latitude: lat,
          longitude: lon,
          label
        }
      };

      // Forward to SMS endpoint logic (simplified)
      const messageId = `loc_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      
      const results = [];
      for (const recipient of recipients) {
        try {
          const twilioMessage = await twilioClient.messages.create({
            body: message,
            from: process.env.TWILIO_FROM_NUMBER,
            to: recipient
          });

          results.push({
            recipient,
            status: 'sent',
            twilioSid: twilioMessage.sid
          });
        } catch (error) {
          results.push({
            recipient,
            status: 'failed',
            error: error.message
          });
        }
      }

      res.status(201).json({
        message_id: messageId,
        location: { lat, lon },
        map_link: mapLink,
        sent_count: results.filter(r => r.status === 'sent').length,
        results
      });

    } catch (error) {
      console.error('Location sharing error:', error);
      res.status(500).json({
        error: 'Internal server error',
        message: 'Failed to share location'
      });
    }
  }
);

// Get SMS status
app.get('/v1/emergency/sms-status/:messageId',
  authenticateApiKey,
  (req, res) => {
    const { messageId } = req.params;
    
    // Find message in history
    const message = smsHistory.find(m => m.id === messageId);
    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }

    res.json({
      message_id: messageId,
      status: message.status,
      timestamp: message.timestamp,
      recipients_count: message.recipients.length,
      sent_count: message.results.filter(r => r.status === 'sent').length,
      failed_count: message.results.filter(r => r.status === 'failed').length
    });
  }
);

// Get SMS history
app.get('/v1/emergency/sms-history',
  authenticateApiKey,
  (req, res) => {
    const limit = parseInt(req.query.limit) || 50;
    const since = req.query.since ? new Date(req.query.since) : null;
    
    let messages = [...smsHistory];
    
    if (since) {
      messages = messages.filter(m => new Date(m.timestamp) >= since);
    }
    
    messages = messages
      .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
      .slice(0, limit);

    res.json({
      messages: messages.map(m => ({
        id: m.id,
        recipients: m.recipients,
        message: m.message.substring(0, 100) + (m.message.length > 100 ? '...' : ''),
        timestamp: m.timestamp,
        status: m.status,
        sent_count: m.results.filter(r => r.status === 'sent').length,
        metadata: m.metadata
      })),
      total: messages.length,
      limit
    });
  }
);

// Twilio webhook for delivery status
app.post('/v1/emergency/sms-webhook/:messageId', (req, res) => {
  const { messageId } = req.params;
  const { MessageStatus, To, MessageSid } = req.body;
  
  console.log(`SMS status update for ${messageId}: ${MessageStatus}`);
  
  // Update status in storage
  const key = `${messageId}_${To}`;
  if (messageStatuses.has(key)) {
    const statusInfo = messageStatuses.get(key);
    statusInfo.status = MessageStatus;
    statusInfo.lastUpdate = new Date();
    messageStatuses.set(key, statusInfo);
  }
  
  res.status(200).send('OK');
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    message: 'The requested endpoint does not exist'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`TeraxAI Backend Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Twilio configured: ${!!process.env.TWILIO_ACCOUNT_SID}`);
});

module.exports = app;
