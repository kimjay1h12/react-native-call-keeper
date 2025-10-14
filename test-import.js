// Quick test to verify the package can be imported
const pkg = require('./package.json');
console.log('✓ Package name:', pkg.name);
console.log('✓ Version:', pkg.version);

try {
  // Test importing the built module
  const CallKeeper = require('./lib/commonjs/index.js');
  console.log('✓ Module imports successfully');
  console.log('✓ Module exports:', Object.keys(CallKeeper));

  // Check if it's the default export
  if (CallKeeper.default) {
    console.log('✓ Has default export');
    const methods = Object.getOwnPropertyNames(
      Object.getPrototypeOf(CallKeeper.default)
    );
    console.log(
      '✓ Available methods:',
      methods
        .filter((m) => m !== 'constructor')
        .slice(0, 10)
        .join(', '),
      '...'
    );
  }

  console.log('\n✅ ALL IMPORT TESTS PASSED!');
} catch (error) {
  console.error('❌ Import failed:', error.message);
  process.exit(1);
}
