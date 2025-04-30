require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const path = require('path');
const cors = require('cors');
const fs = require('fs');

const app = express();

// Enhanced Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Database Connection with Improved Configuration
const connectWithRetry = () => {
  mongoose.connect(process.env.MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 45000,
    maxPoolSize: 10,
    retryWrites: true,
    w: 'majority'
  })
  .then(() => console.log('🚀 Connected to MongoDB Atlas'))
  .catch(err => {
    console.error('❌ MongoDB connection error:', err);
    setTimeout(connectWithRetry, 5000);
  });
};

connectWithRetry();

// Enhanced Product Model with Validation
const productSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Product name is required'],
    trim: true,
    minlength: [2, 'Product name must be at least 2 characters'],
    maxlength: [100, 'Product name cannot exceed 100 characters']
  },
  price: {
    type: Number,
    required: [true, 'Product price is required'],
    min: [0, 'Price must be positive'],
    max: [1000000, 'Price cannot exceed 1,000,000']
  },
  imageUrl: {
    type: String,
    default: '',
    validate: {
      validator: function(v) {
        if (!v) return true;
        const urlPattern = /^(https?|ftp):\/\/[^\s/$.?#].[^\s]*$/i;
        return urlPattern.test(v);
      },
      message: props => `${props.value} is not a valid URL!`
    }
  }
}, { 
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

const Product = mongoose.model('Product', productSchema);

// Enhanced Route Handlers

// Create Product
app.post('/products', async (req, res) => {
  try {
    const { name, price, imageUrl } = req.body;

    // Enhanced validation
    if (!name || typeof name !== 'string') {
      return res.status(400).json({ 
        error: 'Validation error', 
        message: 'Valid name is required' 
      });
    }

    if (!price || isNaN(price) ){
      return res.status(400).json({ 
        error: 'Validation error', 
        message: 'Valid price is required' 
      });
    }

    const product = new Product({ 
      name: name.trim(),
      price: parseFloat(price),
      imageUrl: imageUrl || ''
    });

    await product.save();

    res.status(201).json({
      success: true,
      data: product,
      message: 'Product created successfully'
    });
  } catch (error) {
    console.error('POST /products error:', error);
    
    if (error.name === 'ValidationError') {
      return res.status(400).json({
        error: 'Validation error',
        message: Object.values(error.errors).map(e => e.message).join(', ')
      });
    }
    
    res.status(500).json({ 
      error: 'Server error', 
      message: 'Failed to create product' 
    });
  }
});

// Update Product
app.put('/products/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, price, imageUrl } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ 
        error: 'Invalid ID', 
        message: 'The provided ID is not valid' 
      });
    }

    const product = await Product.findById(id);
    if (!product) {
      return res.status(404).json({ 
        error: 'Not found', 
        message: 'Product not found' 
      });
    }

    // Partial updates allowed
    if (name) product.name = name.trim();
    if (price) product.price = parseFloat(price);
    if (imageUrl !== undefined) product.imageUrl = imageUrl;

    await product.save();

    res.json({
      success: true,
      data: product,
      message: 'Product updated successfully'
    });
  } catch (error) {
    console.error('PUT /products/:id error:', error);
    
    if (error.name === 'ValidationError') {
      return res.status(400).json({
        error: 'Validation error',
        message: Object.values(error.errors).map(e => e.message).join(', ')
      });
    }
    
    res.status(500).json({ 
      error: 'Server error', 
      message: 'Failed to update product' 
    });
  }
});

// Delete Product
app.delete('/products/:id', async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ 
        error: 'Invalid ID', 
        message: 'The provided ID is not valid' 
      });
    }

    const product = await Product.findByIdAndDelete(id);
    if (!product) {
      return res.status(404).json({ 
        error: 'Not found', 
        message: 'Product not found' 
      });
    }

    res.status(200).json({ 
      success: true, 
      data: product,
      message: 'Product deleted successfully'
    });
  } catch (error) {
    console.error('DELETE /products/:id error:', error);
    res.status(500).json({ 
      error: 'Server error', 
      message: 'Failed to delete product' 
    });
  }
});

// Get All Products
app.get('/products', async (req, res) => {
  try {
    const products = await Product.find().sort({ createdAt: -1 });
    res.json({
      success: true,
      count: products.length,
      data: products
    });
  } catch (error) {
    console.error('GET /products error:', error);
    res.status(500).json({ 
      error: 'Server error', 
      message: 'Failed to fetch products' 
    });
  }
});

// Get Single Product
app.get('/products/:id', async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ 
        error: 'Invalid ID', 
        message: 'The provided ID is not valid' 
      });
    }

    const product = await Product.findById(id);
    if (!product) {
      return res.status(404).json({ 
        error: 'Not found', 
        message: 'Product not found' 
      });
    }

    res.json({
      success: true,
      data: product
    });
  } catch (error) {
    console.error('GET /products/:id error:', error);
    res.status(500).json({ 
      error: 'Server error', 
      message: 'Failed to fetch product' 
    });
  }
});

// Enhanced Image Fallback Handler
app.use('/uploads/:imageName', (req, res) => {
  const requestedImage = path.join(__dirname, 'uploads', req.params.imageName);
  
  if (fs.existsSync(requestedImage)) {
    return res.sendFile(requestedImage);
  }

  const fallbackImage = path.join(__dirname, 'uploads', 'placeholder.png');
  if (fs.existsSync(fallbackImage)) {
    return res.sendFile(fallbackImage);
  }

  res.status(404).json({
    error: 'Not found',
    message: 'Image not found'
  });
});

// Enhanced Health Check
app.get('/health', async (req, res) => {
  const dbStatus = mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
  const memoryUsage = process.memoryUsage();
  
  res.json({ 
    status: 'OK',
    dbStatus,
    uptime: process.uptime(),
    memoryUsage,
    timestamp: new Date().toISOString()
  });
});

// Rate Limiting Middleware (Example)
const rateLimit = require('express-rate-limit');
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Enhanced Error Handling
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  
  // Handle mongoose errors
  if (err.name === 'CastError') {
    return res.status(400).json({
      error: 'Invalid data format',
      message: 'The provided data is not in the expected format'
    });
  }
  
  // Handle JSON parse errors
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({
      error: 'Invalid JSON',
      message: 'The request body contains invalid JSON'
    });
  }
  
  res.status(500).json({ 
    error: 'Internal server error', 
    message: 'Something went wrong' 
  });
});

// Start Server with Enhanced Configuration
const port = process.env.PORT || 3000;
const server = app.listen(port, '0.0.0.0', () => {
  console.log(`🟢 Server running on http://localhost:${port}`);
  console.log(`🔵 Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Enhanced Graceful Shutdown
process.on('SIGTERM', () => {
  console.log('🛑 SIGTERM received. Shutting down gracefully...');
  
  server.close(() => {
    mongoose.connection.close(false, () => {
      console.log('🔴 HTTP server closed');
      console.log('🔴 Database connection closed');
      process.exit(0);
    });
  });
  
  // Force shutdown after 10 seconds if graceful shutdown fails
  setTimeout(() => {
    console.error('🛑 Forcing shutdown due to timeout');
    process.exit(1);
  }, 10000);
});