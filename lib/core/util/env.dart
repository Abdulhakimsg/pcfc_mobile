const baseUrl  = String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8080');
const apiToken = String.fromEnvironment('API_TOKEN', defaultValue: '');
const useApi   = String.fromEnvironment('USE_API', defaultValue: 'false') == 'true';