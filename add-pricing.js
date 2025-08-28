const { MedusaApp } = require("@medusajs/framework");

async function addPricing() {
  // Initialize Medusa app
  const { modules } = await MedusaApp({
    mode: "development",
  });

  const productService = modules.productService;
  const pricingService = modules.pricingService;

  try {
    // Get all products
    const products = await productService.listProducts({});
    console.log(`Found ${products.length} products`);

    for (const product of products) {
      console.log(`\nProcessing product: ${product.title}`);
      
      for (const variant of product.variants) {
        console.log(`  Adding price for variant: ${variant.title}`);
        
        // Define different prices for different products
        let price = 99900; // Default €999.00 in cents
        
        if (product.title.toLowerCase().includes('t-shirt')) {
          price = 29900; // €299.00
        } else if (product.title.toLowerCase().includes('sweatpants')) {
          price = 49900; // €499.00  
        } else if (product.title.toLowerCase().includes('shorts')) {
          price = 39900; // €399.00
        } else if (product.title.toLowerCase().includes('sweatshirt')) {
          price = 59900; // €599.00
        }

        try {
          // Create price for EUR region
          await pricingService.createPriceSets({
            variant_id: variant.id,
            prices: [{
              amount: price,
              currency_code: "eur",
              region_id: "reg_01K31Y17E54QDDEQWSBA6T4EQK"
            }]
          });
          
          console.log(`    ✓ Added price €${(price/100).toFixed(2)} for ${variant.title}`);
        } catch (error) {
          console.log(`    ✗ Error adding price for ${variant.title}:`, error.message);
        }
      }
    }

    console.log('\n✅ Pricing setup completed!');
  } catch (error) {
    console.error('Error setting up pricing:', error);
  }
}

addPricing().catch(console.error);