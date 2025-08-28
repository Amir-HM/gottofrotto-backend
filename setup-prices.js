// Simple script to add demo pricing for development
const axios = require('axios');

const BASE_URL = 'http://localhost:9000';

// Sample pricing data
const PRICING = {
  't-shirt': 72000, // 720 SEK
  'sweatpants': 89000, // 890 SEK  
  'shorts': 65000, // 650 SEK
  'sweatshirt': 95000 // 950 SEK
};

async function setupPricing() {
  try {
    console.log('🚀 Setting up pricing for Medusa products...');
    
    // Get products from store API
    const response = await axios.get(`${BASE_URL}/store/products`, {
      headers: {
        'x-publishable-api-key': 'pk_047f75f3185f82002b8627a1ff50ea3766a344853d5412bc3f8e57e15859ca02'
      }
    });

    const products = response.data.products;
    console.log(`📦 Found ${products.length} products`);

    for (const product of products) {
      console.log(`\n📝 Product: ${product.title}`);
      
      // Determine price based on product title
      let price = 72000; // Default price (720 SEK)
      const title = product.title.toLowerCase();
      
      Object.keys(PRICING).forEach(key => {
        if (title.includes(key)) {
          price = PRICING[key];
        }
      });

      console.log(`💰 Setting price: ${price/100} SEK`);
      
      // For now, just log what we would do
      // In a real implementation, we'd update via admin API
      for (const variant of product.variants) {
        console.log(`  ✓ Variant: ${variant.title} → ${price/100} SEK`);
      }
    }

    console.log('\n✅ Pricing setup simulation completed!');
    console.log('\n🔧 To actually set prices, use the Medusa Admin Dashboard at:');
    console.log('   http://localhost:9000/app');
    console.log('\n💡 Or add prices via the admin API with proper authentication.');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

setupPricing();