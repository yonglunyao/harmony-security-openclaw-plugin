import { ReportStoreServer } from './server.js';

const server = new ReportStoreServer();
server.start().catch(console.error);
