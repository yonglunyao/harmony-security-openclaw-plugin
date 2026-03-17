import { KnowledgeBaseServer } from './server.js';

const server = new KnowledgeBaseServer();
server.start().catch(console.error);
