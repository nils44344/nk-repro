import { ImageResponse } from 'next/og';
export function GET() { return new ImageResponse(<div style={{ fontSize: 48 }}>og</div>, { width: 600, height: 300 }); }
