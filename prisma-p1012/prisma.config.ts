import 'dotenv/config';
import { defineConfig, env } from 'prisma/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: { path: 'prisma/migrations' },
  // Migrate needs the DIRECT connection (what `directUrl` used to be). The app's pooled URL goes to the adapter.
  datasource: { url: env('DIRECT_URL') },
});
