import * as jwt from 'jsonwebtoken';
import { passportJwtSecret } from 'jwks-rsa';
import { JwtPayload, JwtHeader, DecodedToken } from './types';
import { ParameterStoreService } from './parameter-store.service';

export class JwtService {
  private jwksClients = new Map<string, any>();
  private parameterStore: ParameterStoreService;

  constructor() {
    this.parameterStore = new ParameterStoreService();
  }

  async verifyToken(token: string): Promise<JwtPayload> {
    try {
      console.log('Starting JWT verification...');
      const decodedToken = jwt.decode(token, { complete: true }) as any;
      
      if (!decodedToken || !decodedToken.header || !decodedToken.payload) {
        console.error('Invalid token format - missing header or payload');
        throw new Error('Invalid token format');
      }

      const { header, payload } = decodedToken;
      console.log('Token header:', JSON.stringify(header, null, 2));
      console.log('Token payload:', JSON.stringify(payload, null, 2));

      // Se for um token do Cognito (tem iss e kid), usar JWKS
      if (header.kid && payload.iss && 
          (payload.iss.includes('cognito-idp') || 
           payload.iss.includes('amazonaws.com') ||
           payload.iss.includes('cognito'))) {
        console.log('Using JWKS verification for Cognito token');
        return await this.verifyWithJWKS(token, payload.iss);
      }

      // Se for um token local (sem iss ou kid), usar secret
      console.log('Using secret verification for local token');
      return await this.verifyWithSecret(token);

    } catch (error) {
      console.error('JWT verification error:', error);
      throw new Error('Token verification failed');
    }
  }

  private async verifyWithJWKS(token: string, issuer: string): Promise<JwtPayload> {
    try {
      const jwksUri = `${issuer}/.well-known/jwks.json`;
      
      // Verificar se já temos um cliente JWKS para este issuer
      if (!this.jwksClients.has(issuer)) {
        const jwksClient = passportJwtSecret({
          cache: true,
          rateLimit: true,
          jwksRequestsPerMinute: 5,
          jwksUri,
        });
        this.jwksClients.set(issuer, jwksClient);
      }

      const jwksClient = this.jwksClients.get(issuer);
      
      return new Promise((resolve, reject) => {
        jwksClient(null, token, (err: any, secret: any) => {
          if (err) {
            reject(err);
            return;
          }

          try {
            const decoded = jwt.verify(token, secret, {
              algorithms: ['RS256'],
              issuer: issuer,
            }) as JwtPayload;
            resolve(decoded);
          } catch (verifyError) {
            reject(verifyError);
          }
        });
      });

    } catch (error) {
      console.error('JWKS verification error:', error);
      throw error;
    }
  }

  private async verifyWithSecret(token: string): Promise<JwtPayload> {
    try {
      // Primeiro tentar buscar do Parameter Store
      let secret: string;
      
      try {
        console.log('Attempting to fetch JWT secret from Parameter Store...');
        secret = await this.parameterStore.getJwtSecret();
        console.log('JWT secret retrieved from Parameter Store successfully');
      } catch (paramError) {
        console.warn('Failed to fetch from Parameter Store, falling back to environment variable:', paramError);
        secret = process.env.JWT_SECRET || '';
      }

      console.log('JWT_SECRET configured:', !!secret);
      console.log('JWT_SECRET length:', secret ? secret.length : 0);
      
      if (!secret) {
        throw new Error('JWT_SECRET not configured in Parameter Store or environment variable');
      }

      console.log('Verifying token with secret...');
      const decoded = jwt.verify(token, secret, {
        algorithms: ['HS256'],
      }) as JwtPayload;

      console.log('Token verified successfully with secret');
      return decoded;
    } catch (error) {
      console.error('Secret verification error:', error);
      throw error;
    }
  }

  extractTenantId(payload: JwtPayload, headers: any): string | null {
    // Priorizar tenant_id do header x-tenant-id (obrigatório para todos os tokens)
    if (headers && headers['x-tenant-id']) {
      console.log('Tenant ID found in x-tenant-id header:', headers['x-tenant-id']);
      return headers['x-tenant-id'];
    }

    // Aceitar também tenantUuid (formato do frontend)
    if (headers && headers['tenantUuid']) {
      console.log('Tenant ID found in tenantUuid header:', headers['tenantUuid']);
      return headers['tenantUuid'];
    }

    // Aceitar também tenantuuid (formato alternativo)
    if (headers && headers['tenantuuid']) {
      console.log('Tenant ID found in tenantuuid header:', headers['tenantuuid']);
      return headers['tenantuuid'];
    }

    // Fallback para payload (apenas para tokens locais que não usam header)
    if (payload.tenant_id) {
      console.log('Tenant ID found in token payload:', payload.tenant_id);
      return payload.tenant_id;
    }

    if (payload['custom:tenant_id']) {
      console.log('Tenant ID found in custom:tenant_id:', payload['custom:tenant_id']);
      return payload['custom:tenant_id'];
    }

    // Se não encontrar, retornar null
    console.log('No tenant ID found in headers or payload');
    console.log('Available headers:', Object.keys(headers || {}));
    return null;
  }
}
