import { SampleStoreServer } from './server.js';

const server = new SampleStoreServer();
server.start().catch(console.error);
