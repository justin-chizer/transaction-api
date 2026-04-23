import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 10 },  // ramp up to 10 users
    { duration: '60s', target: 50 },  // ramp up to 50 users
    { duration: '60s', target: 100 }, // ramp up to 100 users
    { duration: '60s', target: 100 }, // hold at 100 users
    { duration: '30s', target: 0 },   // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% of requests under 500ms
    http_req_failed: ['rate<0.01'],    // less than 1% error rate
  },
  tlsClientCerts: [
    {
      certPath: './certs/client.crt',
      keyPath: './certs/client.key',
      domains: ['chizer.dev.nationsbenefits.com'],
    },
  ],
};

const BASE_URL = 'https://chizer.dev.nationsbenefits.com';

export function setup() {
  // Create a test account to use throughout the load test
  let res = http.post(`${BASE_URL}/api/accounts`,
    JSON.stringify({ owner: 'Load Test User' }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  return { accountId: res.json('id') };
}

export default function (data) {
  const accountId = data.accountId;

  // GET accounts
  let getAccounts = http.get(`${BASE_URL}/api/accounts`);
  check(getAccounts, { 'GET accounts 200': (r) => r.status === 200 });

  // GET transactions
  let getTransactions = http.get(`${BASE_URL}/api/transactions/${accountId}`);
  check(getTransactions, { 'GET transactions 200': (r) => r.status === 200 });

  // POST credit
  let credit = http.post(
    `${BASE_URL}/api/transactions/${accountId}/credit`,
    JSON.stringify({ amount: 10.00, description: 'Load test credit' }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  check(credit, { 'POST credit 201': (r) => r.status === 201 });

  // POST debit
  let debit = http.post(
    `${BASE_URL}/api/transactions/${accountId}/debit`,
    JSON.stringify({ amount: 5.00, description: 'Load test debit' }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  check(debit, { 'POST debit 201': (r) => r.status === 201 });

  sleep(1);
}