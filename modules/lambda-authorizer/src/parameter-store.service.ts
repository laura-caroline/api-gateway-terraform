import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';

export class ParameterStoreService {
  private ssmClient: SSMClient;
  private cache = new Map<string, { value: string; expiry: number }>();
  private readonly CACHE_TTL = 5 * 60 * 1000; // 5 minutos

  constructor() {
    this.ssmClient = new SSMClient({ region: process.env.AWS_REGION || 'us-east-1' });
  }

  async getParameter(parameterName: string, withDecryption = true): Promise<string> {
    try {
      // Verificar cache primeiro
      const cached = this.cache.get(parameterName);
      if (cached && Date.now() < cached.expiry) {
        console.log(`Parameter ${parameterName} retrieved from cache`);
        return cached.value;
      }

      console.log(`Fetching parameter ${parameterName} from Parameter Store...`);

      const command = new GetParameterCommand({
        Name: parameterName,
        WithDecryption: withDecryption,
      });

      const response = await this.ssmClient.send(command);
      
      if (!response.Parameter?.Value) {
        throw new Error(`Parameter ${parameterName} not found or has no value`);
      }

      const value = response.Parameter.Value;

      // Armazenar no cache
      this.cache.set(parameterName, {
        value,
        expiry: Date.now() + this.CACHE_TTL,
      });

      console.log(`Parameter ${parameterName} retrieved successfully`);
      return value;

    } catch (error) {
      console.error(`Error fetching parameter ${parameterName}:`, error);
      throw new Error(`Failed to retrieve parameter ${parameterName}: ${error}`);
    }
  }

  async getJwtSecret(): Promise<string> {
    const paramName = process.env.JWT_SECRET_PARAM_NAME || '/common.prod/JWT_SECRET';
    return await this.getParameter(paramName, true);
  }

  clearCache(): void {
    this.cache.clear();
    console.log('Parameter Store cache cleared');
  }
}