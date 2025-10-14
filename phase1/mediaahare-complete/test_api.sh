#!/bin/bash

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Testing MediaShare API Endpoints                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "1️⃣  Health Check:"
curl -s http://localhost:8000/health | python3 -m json.tool
echo ""

echo "2️⃣  Root Endpoint:"
curl -s http://localhost:8000/ | python3 -m json.tool
echo ""

echo "3️⃣  Metadata:"
curl -s http://localhost:8000/metadata | python3 -m json.tool
echo ""

echo "4️⃣  Readiness:"
curl -s http://localhost:8000/ready | python3 -m json.tool
echo ""

echo "5️⃣  API Documentation (first 20 lines):"
curl -s http://localhost:8000/openapi.json | python3 -m json.tool | head -20
echo ""

echo "✅ All endpoints tested successfully!"
