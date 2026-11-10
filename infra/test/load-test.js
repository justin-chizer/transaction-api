import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 10 },
    { duration: '60s', target: 50 },
    { duration: '60s', target: 100 },
    { duration: '60s', target: 100 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
  tlsAuth: [
    {
      domains: ['chizer.dev.nationsbenefits.com'],
      cert: open('./../mtls/cloudflare.crt'),
      key: open('./../mtls/cloudflare.key'),
    },
  ],
};

const BASE_URL = 'https://chizer.dev.nationsbenefits.com';

export function setup() {
  let res = http.post(`${BASE_URL}/api/accounts`,
    JSON.stringify({ owner: 'Load Test User' }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  return { accountId: res.json('id') };
}

export default function (data) {
  const accountId = data.accountId;

  let getAccounts = http.get(`${BASE_URL}/api/accounts`);
  check(getAccounts, { 'GET accounts 200': (r) => r.status === 200 });

  let getTransactions = http.get(`${BASE_URL}/api/transactions/${accountId}`);
  check(getTransactions, { 'GET transactions 200': (r) => r.status === 200 });

  let credit = http.post(
    `${BASE_URL}/api/transactions/${accountId}/credit`,
    JSON.stringify({ amount: 10.00, description: 'Load test credit' }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  check(credit, { 'POST credit 201': (r) => r.status === 201 });

  let debit = http.post(
    `${BASE_URL}/api/transactions/${accountId}/debit`,
    JSON.stringify({ amount: 5.00, description: 'Load test debit' }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  check(debit, { 'POST debit 201': (r) => r.status === 201 });

  sleep(1);
}