export class DomainException extends Error {
  constructor(
    message: string,
    public readonly code?: string,
  ) {
    super(message);
    this.name = 'DomainException';
  }
}

export class EntityNotFoundException extends DomainException {
  constructor(entity: string, id: string) {
    super(`${entity} con id '${id}' no encontrado`, 'NOT_FOUND');
    this.name = 'EntityNotFoundException';
  }
}

export class BusinessRuleViolationException extends DomainException {
  constructor(message: string) {
    super(message, 'BUSINESS_RULE');
    this.name = 'BusinessRuleViolationException';
  }
}
