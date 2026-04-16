const fs = require('fs');

const spec = JSON.parse(fs.readFileSync('openapi.3.1.json', 'utf8'));

// Fix version
spec.openapi = '3.0.3';

// Fix type arrays throughout the spec
function fixTypes(obj) {
    if (obj === null || typeof obj !== 'object') return;

    if (Array.isArray(obj)) {
        obj.forEach(item => fixTypes(item));
        return;
    }

    // Fix type: ["number", "string"] -> type: "number"
    // Fix type: ["null", "string"] -> type: "string", nullable: true
    // Fix type: ["null", "integer", "string"] -> type: "integer", nullable: true
    if (Array.isArray(obj.type)) {
        const types = obj.type.filter(t => t !== 'null');
        const isNullable = obj.type.includes('null');

        // Pick the most specific non-null type
        // Prefer number/integer over string
        const preferred = types.find(t => t !== 'string') || types[0];
        obj.type = preferred;

        if (isNullable) {
            obj.nullable = true;
        }

        // Remove pattern from numeric types - it's a 3.1 artifact
        if (obj.type === 'number' || obj.type === 'integer') {
            delete obj.pattern;
        }
    }

    // Remove text/json and application/*+json from request bodies
    if (obj.content) {
        delete obj.content['text/json'];
        delete obj.content['application/*+json'];
        delete obj.content['text/plain'];
    }

    Object.values(obj).forEach(value => fixTypes(value));
}

fixTypes(spec);

fs.writeFileSync('openapi.json', JSON.stringify(spec, null, 2));
console.log('✅ Converted to OpenAPI 3.0.3');