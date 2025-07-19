#!/bin/bash

# Flutter Test Coverage Script
# This script runs all tests and generates coverage reports

echo "🧪 Running Flutter tests with coverage..."

# Clean previous coverage data
echo "🧹 Cleaning previous coverage data..."
rm -rf coverage/
mkdir -p coverage

# Run tests with coverage
echo "🚀 Running tests..."
flutter test --coverage

# Check if tests passed
if [ $? -eq 0 ]; then
    echo "✅ Tests passed!"
    
    # Generate HTML coverage report
    if command -v genhtml &> /dev/null; then
        echo "📊 Generating HTML coverage report..."
        genhtml coverage/lcov.info -o coverage/html
        echo "📋 Coverage report generated at: coverage/html/index.html"
    else
        echo "⚠️  genhtml not found. Install lcov to generate HTML reports:"
        echo "   macOS: brew install lcov"
        echo "   Ubuntu: sudo apt-get install lcov"
    fi
    
    # Display coverage summary
    if command -v lcov &> /dev/null; then
        echo "📈 Coverage Summary:"
        lcov --summary coverage/lcov.info
    fi
    
    echo "🎉 Coverage analysis complete!"
    echo "📁 Coverage files:"
    echo "   - LCOV: coverage/lcov.info"
    echo "   - HTML: coverage/html/index.html (if genhtml is available)"
    
else
    echo "❌ Tests failed!"
    exit 1
fi