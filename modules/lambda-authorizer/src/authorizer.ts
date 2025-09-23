import { APIGatewayRequestAuthorizerEvent, APIGatewayAuthorizerResult, Context } from 'aws-lambda';
import { JwtService } from './jwt.service';
import { UserInfo, AuthorizerResponse } from './types';

export class LambdaAuthorizer {
  private jwtService: JwtService;

  constructor() {
    this.jwtService = new JwtService();
  }

  async authorize(event: APIGatewayRequestAuthorizerEvent, context: Context): Promise<any> {
    try {
      console.log('Authorization event:', JSON.stringify(event, null, 2));

      // Extrair token do header Authorization
      const authHeader = event.headers?.Authorization || event.headers?.authorization;
      console.log('Authorization header received:', authHeader);
      
      if (!authHeader) {
        console.error('No Authorization header provided');
        throw new Error('No Authorization header provided');
      }
      
      const token = this.extractToken(authHeader);
      if (!token) {
        console.error('Invalid Authorization header format. Expected: Bearer <token>');
        console.error('Received:', authHeader);
        throw new Error('Invalid Authorization header format. Expected: Bearer <token>');
      }

      // Verificar e decodificar o token JWT
      const payload = await this.jwtService.verifyToken(token);
      console.log('JWT payload:', JSON.stringify(payload, null, 2));

      // Extrair tenant_id do header x-tenant-id (obrigatório)
      const headers = event.headers || {};
      console.log('All headers received:', JSON.stringify(headers, null, 2));
      
      const tenantId = this.jwtService.extractTenantId(payload, headers);
      if (!tenantId) {
        console.error('Tenant ID not found in x-tenant-id header');
        console.error('Available headers:', Object.keys(headers));
        console.error('Token payload:', JSON.stringify(payload, null, 2));
        throw new Error('Tenant ID not found in x-tenant-id header');
      }

      // Criar informações do usuário baseadas no payload do token
      const user: UserInfo = {
        id: payload.sub || payload.user_id || payload.id,
        email: payload.email,
        tenantId: tenantId,
      };

      // Gerar política de autorização
      const policy = this.generatePolicy('Allow', event.methodArn);
      
      // Retornar resposta de autorização com contexto
      const response: any = {
        principalId: user.id,
        policyDocument: policy,
        context: {
          user: JSON.stringify(user),
          tenantId: tenantId,
          email: user.email,
          userId: user.id,
        },
      };

      console.log('Authorization successful for user:', user.email);
      return response;

    } catch (error) {
      console.error('Authorization error:', error);
      
      // Retornar política de negação em caso de erro
      const policy = this.generatePolicy('Deny', event.methodArn);
      return {
        principalId: 'anonymous',
        policyDocument: policy,
      };
    }
  }

  private extractToken(authorizationToken: string): string | null {
    if (!authorizationToken) {
      console.log('No authorization token provided');
      return null;
    }

    console.log('Processing authorization token:', authorizationToken);

    // Limpar espaços em branco
    const cleanToken = authorizationToken.trim();
    
    // Verificar se começa com "Bearer "
    if (!cleanToken.startsWith('Bearer ')) {
      console.log('Token does not start with "Bearer "');
      return null;
    }

    const parts = cleanToken.split(' ');
    if (parts.length !== 2) {
      console.log('Token does not have exactly 2 parts when split by space');
      return null;
    }

    if (parts[0] !== 'Bearer') {
      console.log('First part is not "Bearer"');
      return null;
    }

    const token = parts[1];
    if (!token || token.length === 0) {
      console.log('Token part is empty');
      return null;
    }

    console.log('Successfully extracted token');
    return token;
  }


  private generatePolicy(effect: 'Allow' | 'Deny', resource: string): any {
    return {
      Version: '2012-10-17',
      Statement: [
        {
          Action: 'execute-api:Invoke',
          Effect: effect,
          Resource: resource,
        },
      ],
    };
  }

}

// Handler principal do Lambda
export const handler = async (
  event: APIGatewayRequestAuthorizerEvent,
  context: Context
): Promise<any> => {
  const authorizer = new LambdaAuthorizer();
  return await authorizer.authorize(event, context);
};
