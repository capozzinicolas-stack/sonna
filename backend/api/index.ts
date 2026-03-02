import type { VercelRequest, VercelResponse } from '@vercel/node';

let app: any;
let initError: any;

try {
  app = require('../src/index').default;
} catch (e) {
  initError = e;
}

export default function handler(req: VercelRequest, res: VercelResponse) {
  if (initError) {
    return res.status(500).json({
      error: 'INIT_FAILED',
      message: initError?.message || 'Unknown error',
      stack: initError?.stack?.split('\n').slice(0, 5),
    });
  }
  return app(req, res);
}
