export interface UserInfo {
  id: string;
  email: string;
  tenantId?: string;
  [key: string]: any;
}

export interface JwtPayload {
  iss: string;
  sub: string;
  email: string;
  [key: string]: any;
}

export interface JwtHeader {
  kid: string;
  alg: string;
  [key: string]: any;
}

export interface DecodedToken {
  header: JwtHeader;
  payload: JwtPayload;
}

export interface AuthorizerContext {
  user: UserInfo;
  tenantId?: string;
  [key: string]: any;
}

export interface AuthorizerResponse {
  principalId: string;
  policyDocument: {
    Version: string;
    Statement: Array<{
      Action: string;
      Effect: string;
      Resource: string;
    }>;
  };
  context?: AuthorizerContext;
}
