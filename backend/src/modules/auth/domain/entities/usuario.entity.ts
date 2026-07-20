export class Usuario {
  constructor(
    public readonly id: string,
    public readonly codigoEmpresa: string,
    public readonly codigo: string,
    public readonly nombre: string,
    public readonly passwordHash: string,
    public readonly nivel: string,
    public readonly activo: boolean,
    public readonly dni?: string,
    public readonly email?: string,
    public readonly menus?: string[],
  ) {}

  isActive(): boolean {
    return this.activo;
  }

  canLogin(): boolean {
    return this.activo;
  }
}
