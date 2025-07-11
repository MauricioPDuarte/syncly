# Guia de Implementação do Backend para Syncly com NestJS e Prisma

## 🎯 Visão Geral

Este guia explica como implementar os endpoints do backend usando **NestJS** e **Prisma** para suportar a **sincronização incremental** do Syncly. A sincronização incremental permite que o cliente baixe apenas dados novos, modificados ou excluídos, em vez de todos os dados a cada sincronização.

## 🗄️ Estratégia de Log de Deleção

Para garantir que o sistema de sincronização funcione corretamente, implementaremos uma **tabela de log de deleção** que registra todos os itens excluídos, permitindo que o cliente saiba quais registros foram removidos desde a última sincronização.

## 📋 Benefícios da Sincronização Incremental

- ⚡ **Performance**: Sincronizações até 90% mais rápidas
- 📱 **Economia de Dados**: Redução significativa no tráfego de rede
- 🔋 **Menor Consumo**: Reduz uso de bateria e processamento
- 🛡️ **Segurança**: Fallback automático para sincronização completa
- 📦 **Paginação**: Suporte a processamento em lotes para grandes volumes

## 🔄 Como Funciona

1. **Cliente envia timestamp** da última sincronização (opcional)
2. **Backend determina** se é sincronização incremental ou completa
3. **Backend retorna** apenas dados modificados desde o timestamp
4. **Cliente processa** mudanças seletivamente
5. **Cliente salva** novo timestamp para próxima sincronização

## 📤 Formato da Requisição

O Syncly enviará requisições HTTP GET com os seguintes parâmetros:

```http
GET /api/sync/data
Authorization: Bearer <token>
Content-Type: application/json

Query Parameters:
last_sync: 2024-01-15T10:30:00.000Z  (opcional - para sincronização incremental)
user_id: 12345                        (se necessário para filtrar dados do usuário)
page: 1                               (opcional - número da página para paginação)
limit: 1000                           (opcional - limite de registros por página)
entity_types: users,products          (opcional - tipos específicos de entidades)
```

### Lógica de Decisão

- **Se `last_sync` está presente**: Retornar apenas dados modificados desde essa data
- **Se `last_sync` está ausente**: Retornar todos os dados (sincronização completa)
- **Se `page` está presente**: Retornar dados paginados
- **Se `limit` está presente**: Limitar número de registros por resposta

## 📥 Formato da Resposta

O backend deve retornar dados no seguinte formato JSON:

```json
{
  "success": true,
  "sync_timestamp": "2024-01-15T15:45:30.123Z",
  "is_incremental": true,
  "pagination": {
    "current_page": 1,
    "total_pages": 3,
    "total_records": 2500,
    "records_per_page": 1000,
    "has_next_page": true,
    "has_previous_page": false
  },
  "data": {
    "users": {
      "created": [
        {
          "id": "user_123",
          "name": "João Silva",
          "email": "joao@email.com",
          "created_at": "2024-01-15T14:20:00.000Z",
          "updated_at": "2024-01-15T14:20:00.000Z"
        }
      ],
      "updated": [
        {
          "id": "user_456",
          "name": "Maria Santos - Atualizado",
          "email": "maria@email.com",
          "created_at": "2024-01-10T10:00:00.000Z",
          "updated_at": "2024-01-15T15:30:00.000Z"
        }
      ],
      "deleted": ["user_789", "user_101"]
    },
    "products": {
      "created": [
        {
          "id": "prod_001",
          "name": "Produto Novo",
          "price": 29.99,
          "created_at": "2024-01-15T13:15:00.000Z",
          "updated_at": "2024-01-15T13:15:00.000Z"
        }
      ],
      "updated": [],
      "deleted": ["prod_002"]
    }
  }
}
```

### Campos da Resposta

| Campo | Tipo | Descrição |
|-------|------|----------|
| `success` | boolean | Indica se a operação foi bem-sucedida |
| `sync_timestamp` | string | Timestamp atual do servidor (ISO 8601) |
| `is_incremental` | boolean | Indica se foi sincronização incremental |
| `pagination` | object | Informações de paginação (opcional) |
| `data` | object | Dados organizados por tipo de entidade |

### Campos de Paginação

| Campo | Tipo | Descrição |
|-------|------|----------|
| `current_page` | number | Página atual (1-indexed) |
| `total_pages` | number | Total de páginas disponíveis |
| `total_records` | number | Total de registros encontrados |
| `records_per_page` | number | Número de registros por página |
| `has_next_page` | boolean | Indica se há próxima página |
| `has_previous_page` | boolean | Indica se há página anterior |

## 📊 Estrutura dos Dados

Cada tipo de entidade deve conter três arrays:

### 🆕 created
- Array com registros **criados** desde o `last_sync`
- Deve incluir todos os campos do registro
- Obrigatório: `id`, `created_at`, `updated_at`
- Usar formato ISO 8601 para datas

### 🔄 updated
- Array com registros **modificados** desde o `last_sync`
- Deve incluir todos os campos atualizados
- O `updated_at` deve ser posterior ao `last_sync`
- Incluir registro completo, não apenas campos alterados

### 🗑️ deleted
- Array com **IDs** dos registros excluídos desde o `last_sync`
- Apenas os IDs dos registros excluídos
- O cliente removerá estes registros localmente
- Importante para manter consistência dos dados

## 🗄️ Schema do Prisma

### Estrutura de Tabelas com Log de Deleção

```prisma
// schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// Tabela principal de usuários
model User {
  id        String   @id @default(cuid())
  name      String
  email     String   @unique
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  @@map("users")
  @@index([createdAt])
  @@index([updatedAt])
}

// Tabela principal de produtos
model Product {
  id          String   @id @default(cuid())
  name        String
  description String?
  price       Decimal
  createdAt   DateTime @default(now()) @map("created_at")
  updatedAt   DateTime @updatedAt @map("updated_at")

  @@map("products")
  @@index([createdAt])
  @@index([updatedAt])
}

// Tabela de log de deleção para sincronização
model DeletionLog {
  id         String   @id @default(cuid())
  entityType String   @map("entity_type") // 'users', 'products', etc.
  entityId   String   @map("entity_id")   // ID do registro deletado
  deletedAt  DateTime @default(now()) @map("deleted_at")
  deletedBy  String?  @map("deleted_by")  // ID do usuário que deletou (opcional)
  metadata   Json?                        // Dados adicionais sobre a deleção

  @@map("deletion_logs")
  @@index([entityType, deletedAt])
  @@index([deletedAt])
}
```

### Migrations

```sql
-- Migration para criar as tabelas
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "products" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "price" DECIMAL(65,30) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "products_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "deletion_logs" (
    "id" TEXT NOT NULL,
    "entity_type" TEXT NOT NULL,
    "entity_id" TEXT NOT NULL,
    "deleted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_by" TEXT,
    "metadata" JSONB,
    CONSTRAINT "deletion_logs_pkey" PRIMARY KEY ("id")
);

-- Índices para performance
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");
CREATE INDEX "users_created_at_idx" ON "users"("created_at");
CREATE INDEX "users_updated_at_idx" ON "users"("updated_at");
CREATE INDEX "products_created_at_idx" ON "products"("created_at");
CREATE INDEX "products_updated_at_idx" ON "products"("updated_at");
CREATE INDEX "deletion_logs_entity_type_deleted_at_idx" ON "deletion_logs"("entity_type", "deleted_at");
CREATE INDEX "deletion_logs_deleted_at_idx" ON "deletion_logs"("deleted_at");
```

## 🚀 Implementação com NestJS e Prisma

### Service de Sincronização com Paginação

```typescript
// sync.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from './prisma.service';
import { SyncResponseDto, SyncQueryDto, PaginationInfo } from './dto/sync.dto';

@Injectable()
export class SyncService {
  private readonly DEFAULT_PAGE_SIZE = 1000;
  private readonly MAX_PAGE_SIZE = 5000;
  
  constructor(private prisma: PrismaService) {}

  async syncData(query: SyncQueryDto): Promise<SyncResponseDto> {
    const { last_sync, user_id, page = 1, limit, entity_types } = query;
    const currentTimestamp = new Date().toISOString();
    const isIncremental = !!last_sync;
    const pageSize = Math.min(limit || this.DEFAULT_PAGE_SIZE, this.MAX_PAGE_SIZE);
    const skip = (page - 1) * pageSize;
    
    const result: SyncResponseDto = {
      success: true,
      sync_timestamp: currentTimestamp,
      is_incremental: isIncremental,
      data: {}
    };
    
    // Determinar quais entidades processar
    const entitiesToSync = entity_types ? entity_types.split(',') : ['users', 'products'];
    
    if (isIncremental) {
      const syncDate = new Date(last_sync);
      
      // Processar cada tipo de entidade com paginação
      for (const entityType of entitiesToSync) {
        if (entityType === 'users') {
          const [usersCreated, usersUpdated, usersDeleted, totalCount] = await Promise.all([
            this.getUsersCreated(syncDate, skip, pageSize),
            this.getUsersUpdated(syncDate, skip, pageSize),
            this.getDeletedEntities('users', syncDate),
            this.countUsersModified(syncDate)
          ]);
          
          result.data.users = {
            created: usersCreated,
            updated: usersUpdated,
            deleted: usersDeleted
          };
          
          // Adicionar informações de paginação apenas se houver dados suficientes
          if (totalCount > pageSize) {
            result.pagination = this.calculatePagination(page, pageSize, totalCount);
          }
        }
        
        if (entityType === 'products') {
          const [productsCreated, productsUpdated, productsDeleted, totalCount] = await Promise.all([
            this.getProductsCreated(syncDate, skip, pageSize),
            this.getProductsUpdated(syncDate, skip, pageSize),
            this.getDeletedEntities('products', syncDate),
            this.countProductsModified(syncDate)
          ]);
          
          result.data.products = {
            created: productsCreated,
            updated: productsUpdated,
            deleted: productsDeleted
          };
          
          // Se não há paginação definida ainda, calcular para produtos
          if (!result.pagination && totalCount > pageSize) {
            result.pagination = this.calculatePagination(page, pageSize, totalCount);
          }
        }
      }
      
    } else {
      // Sincronização completa com paginação
      for (const entityType of entitiesToSync) {
        if (entityType === 'users') {
          const [allUsers, totalUsers] = await Promise.all([
            this.prisma.user.findMany({
              skip,
              take: pageSize,
              orderBy: { createdAt: 'asc' }
            }),
            this.prisma.user.count()
          ]);
          
          result.data.users = {
            created: allUsers,
            updated: [],
            deleted: []
          };
          
          if (totalUsers > pageSize) {
            result.pagination = this.calculatePagination(page, pageSize, totalUsers);
          }
        }
        
        if (entityType === 'products') {
          const [allProducts, totalProducts] = await Promise.all([
            this.prisma.product.findMany({
              skip,
              take: pageSize,
              orderBy: { createdAt: 'asc' }
            }),
            this.prisma.product.count()
          ]);
          
          result.data.products = {
            created: allProducts,
            updated: [],
            deleted: []
          };
          
          if (!result.pagination && totalProducts > pageSize) {
            result.pagination = this.calculatePagination(page, pageSize, totalProducts);
          }
        }
      }
    }
    
    return result;
  }
  
  private calculatePagination(page: number, pageSize: number, totalRecords: number): PaginationInfo {
    const totalPages = Math.ceil(totalRecords / pageSize);
    
    return {
      current_page: page,
      total_pages: totalPages,
      total_records: totalRecords,
      records_per_page: pageSize,
      has_next_page: page < totalPages,
      has_previous_page: page > 1
    };
  }
  
  private async getUsersCreated(syncDate: Date, skip: number = 0, take: number = 1000) {
    return this.prisma.user.findMany({
      where: {
        createdAt: { gt: syncDate }
      },
      skip,
      take,
      orderBy: { createdAt: 'asc' }
    });
  }
  
  private async getUsersUpdated(syncDate: Date, skip: number = 0, take: number = 1000) {
    return this.prisma.user.findMany({
      where: {
        updatedAt: { gt: syncDate },
        createdAt: { lte: syncDate }
      },
      skip,
      take,
      orderBy: { updatedAt: 'asc' }
    });
  }
  
  private async countUsersModified(syncDate: Date): Promise<number> {
    const [createdCount, updatedCount] = await Promise.all([
      this.prisma.user.count({
        where: { createdAt: { gt: syncDate } }
      }),
      this.prisma.user.count({
        where: {
          updatedAt: { gt: syncDate },
          createdAt: { lte: syncDate }
        }
      })
    ]);
    
    return createdCount + updatedCount;
  }
  
  private async getProductsCreated(syncDate: Date, skip: number = 0, take: number = 1000) {
    return this.prisma.product.findMany({
      where: {
        createdAt: { gt: syncDate }
      },
      skip,
      take,
      orderBy: { createdAt: 'asc' }
    });
  }
  
  private async getProductsUpdated(syncDate: Date, skip: number = 0, take: number = 1000) {
    return this.prisma.product.findMany({
      where: {
        updatedAt: { gt: syncDate },
        createdAt: { lte: syncDate }
      },
      skip,
      take,
      orderBy: { updatedAt: 'asc' }
    });
  }
  
  private async countProductsModified(syncDate: Date): Promise<number> {
    const [createdCount, updatedCount] = await Promise.all([
      this.prisma.product.count({
        where: { createdAt: { gt: syncDate } }
      }),
      this.prisma.product.count({
        where: {
          updatedAt: { gt: syncDate },
          createdAt: { lte: syncDate }
        }
      })
    ]);
    
    return createdCount + updatedCount;
  }
  
  private async getDeletedEntities(entityType: string, syncDate: Date): Promise<string[]> {
    const deletedLogs = await this.prisma.deletionLog.findMany({
      where: {
        entityType,
        deletedAt: { gt: syncDate }
      },
      select: { entityId: true },
      orderBy: { deletedAt: 'asc' }
    });
    
    return deletedLogs.map(log => log.entityId);
  }
  
  // Método para registrar deleção
  async logDeletion(entityType: string, entityId: string, deletedBy?: string, metadata?: any) {
    await this.prisma.deletionLog.create({
      data: {
        entityType,
        entityId,
        deletedBy,
        metadata
      }
    });
  }
}
```

### Controller de Sincronização

```typescript
// sync.controller.ts
import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { SyncService } from './sync.service';
import { SyncQueryDto, SyncResponseDto } from './dto/sync.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@ApiTags('Sincronização')
@Controller('api/sync')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Get('data')
  @ApiOperation({ summary: 'Sincronizar dados' })
  @ApiResponse({ status: 200, description: 'Dados sincronizados com sucesso', type: SyncResponseDto })
  async syncData(@Query() query: SyncQueryDto): Promise<SyncResponseDto> {
    return this.syncService.syncData(query);
  }
}
```

### DTOs

```typescript
// dto/sync.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsDateString, IsNumber, Min, Max, IsArray } from 'class-validator';
import { Type, Transform } from 'class-transformer';

export class SyncQueryDto {
  @ApiPropertyOptional({ description: 'Timestamp da última sincronização (ISO 8601)' })
  @IsOptional()
  @IsDateString()
  last_sync?: string;
  
  @ApiPropertyOptional({ description: 'ID do usuário para filtrar dados' })
  @IsOptional()
  @IsString()
  user_id?: string;
  
  @ApiPropertyOptional({ description: 'Número da página (1-indexed)', minimum: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number = 1;
  
  @ApiPropertyOptional({ description: 'Limite de registros por página', minimum: 1, maximum: 5000, default: 1000 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(5000)
  limit?: number;
  
  @ApiPropertyOptional({ description: 'Tipos de entidades para sincronizar (separados por vírgula)', example: 'users,products' })
  @IsOptional()
  @IsString()
  entity_types?: string;
}

export class PaginationInfo {
  @ApiProperty({ description: 'Página atual (1-indexed)' })
  current_page: number;
  
  @ApiProperty({ description: 'Total de páginas disponíveis' })
  total_pages: number;
  
  @ApiProperty({ description: 'Total de registros encontrados' })
  total_records: number;
  
  @ApiProperty({ description: 'Número de registros por página' })
  records_per_page: number;
  
  @ApiProperty({ description: 'Indica se há próxima página' })
  has_next_page: boolean;
  
  @ApiProperty({ description: 'Indica se há página anterior' })
  has_previous_page: boolean;
}

export class EntityDataDto {
  @ApiProperty({ description: 'Registros criados' })
  created: any[];
  
  @ApiProperty({ description: 'Registros atualizados' })
  updated: any[];
  
  @ApiProperty({ description: 'IDs dos registros excluídos' })
  deleted: string[];
}

export class SyncDataDto {
  @ApiPropertyOptional({ description: 'Dados de usuários' })
  users?: EntityDataDto;
  
  @ApiPropertyOptional({ description: 'Dados de produtos' })
  products?: EntityDataDto;
}

export class SyncResponseDto {
  @ApiProperty({ description: 'Indica se a operação foi bem-sucedida' })
  success: boolean;
  
  @ApiProperty({ description: 'Timestamp atual do servidor (ISO 8601)' })
  sync_timestamp: string;
  
  @ApiProperty({ description: 'Indica se foi sincronização incremental' })
  is_incremental: boolean;
  
  @ApiPropertyOptional({ description: 'Informações de paginação (presente quando há muitos dados)' })
  pagination?: PaginationInfo;
  
  @ApiProperty({ description: 'Dados organizados por tipo de entidade' })
  data: SyncDataDto;
}
```

### Services para Gerenciar Deleções

```typescript
// user.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from './prisma.service';
import { SyncService } from './sync.service';
import { CreateUserDto, UpdateUserDto } from './dto/user.dto';

@Injectable()
export class UserService {
  constructor(
    private prisma: PrismaService,
    private syncService: SyncService
  ) {}

  async create(createUserDto: CreateUserDto) {
    return this.prisma.user.create({
      data: createUserDto
    });
  }

  async update(id: string, updateUserDto: UpdateUserDto) {
    return this.prisma.user.update({
      where: { id },
      data: updateUserDto
    });
  }

  async delete(id: string, deletedBy?: string) {
    // Usar transação para garantir consistência
    return this.prisma.$transaction(async (tx) => {
      // Buscar o usuário antes de deletar (para metadata)
      const user = await tx.user.findUnique({ where: { id } });
      
      if (!user) {
        throw new Error('Usuário não encontrado');
      }
      
      // Deletar o usuário
      await tx.user.delete({ where: { id } });
      
      // Registrar no log de deleção
      await tx.deletionLog.create({
        data: {
          entityType: 'users',
          entityId: id,
          deletedBy,
          metadata: {
            name: user.name,
            email: user.email
          }
        }
      });
      
      return { success: true, message: 'Usuário deletado com sucesso' };
    });
  }

  async findAll() {
    return this.prisma.user.findMany();
  }

  async findOne(id: string) {
    return this.prisma.user.findUnique({ where: { id } });
  }
}
```

```typescript
// product.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from './prisma.service';
import { SyncService } from './sync.service';
import { CreateProductDto, UpdateProductDto } from './dto/product.dto';

@Injectable()
export class ProductService {
  constructor(
    private prisma: PrismaService,
    private syncService: SyncService
  ) {}

  async create(createProductDto: CreateProductDto) {
    return this.prisma.product.create({
      data: createProductDto
    });
  }

  async update(id: string, updateProductDto: UpdateProductDto) {
    return this.prisma.product.update({
      where: { id },
      data: updateProductDto
    });
  }

  async delete(id: string, deletedBy?: string) {
    return this.prisma.$transaction(async (tx) => {
      const product = await tx.product.findUnique({ where: { id } });
      
      if (!product) {
        throw new Error('Produto não encontrado');
      }
      
      await tx.product.delete({ where: { id } });
      
      await tx.deletionLog.create({
        data: {
          entityType: 'products',
          entityId: id,
          deletedBy,
          metadata: {
            name: product.name,
            price: product.price.toString()
          }
        }
      });
      
      return { success: true, message: 'Produto deletado com sucesso' };
    });
  }

  async findAll() {
    return this.prisma.product.findMany();
  }

  async findOne(id: string) {
    return this.prisma.product.findUnique({ where: { id } });
  }
}
```

### Detecção Automática de Deleções com Prisma

#### Opção 1: Middleware do Prisma (Recomendado)

```typescript
// prisma-middleware.service.ts
import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Injectable()
export class PrismaMiddlewareService implements OnModuleInit {
  constructor(private prisma: PrismaService) {}

  onModuleInit() {
    this.prisma.$use(async (params, next) => {
      // Interceptar operações de delete
      if (params.action === 'delete' || params.action === 'deleteMany') {
        const entityType = params.model?.toLowerCase();
        
        if (entityType && ['user', 'product'].includes(entityType)) {
          // Para delete único
          if (params.action === 'delete' && params.args.where?.id) {
            await this.logDeletion(
              `${entityType}s`, // users, products
              params.args.where.id,
              params.args.deletedBy // Se passado como argumento
            );
          }
          
          // Para deleteMany, buscar IDs antes de deletar
          if (params.action === 'deleteMany') {
            const records = await this.prisma[entityType].findMany({
              where: params.args.where,
              select: { id: true }
            });
            
            // Registrar cada ID deletado
            for (const record of records) {
              await this.logDeletion(
                `${entityType}s`,
                record.id,
                params.args.deletedBy
              );
            }
          }
        }
      }
      
      return next(params);
    });
  }

  private async logDeletion(entityType: string, entityId: string, deletedBy?: string) {
    try {
      await this.prisma.deletionLog.create({
        data: {
          entityType,
          entityId,
          deletedBy,
          metadata: {
            deletedVia: 'prisma-middleware',
            timestamp: new Date().toISOString()
          }
        }
      });
    } catch (error) {
      console.error('Erro ao registrar log de deleção:', error);
    }
  }
}
```

#### Opção 2: Triggers de Banco de Dados

```sql
-- Trigger para tabela users
CREATE OR REPLACE FUNCTION log_user_deletion()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO deletion_logs (id, entity_type, entity_id, deleted_at, metadata)
    VALUES (
        gen_random_uuid(),
        'users',
        OLD.id,
        NOW(),
        json_build_object(
            'name', OLD.name,
            'email', OLD.email,
            'deleted_via', 'database_trigger'
        )
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_deletion_trigger
    BEFORE DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION log_user_deletion();

-- Trigger para tabela products
CREATE OR REPLACE FUNCTION log_product_deletion()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO deletion_logs (id, entity_type, entity_id, deleted_at, metadata)
    VALUES (
        gen_random_uuid(),
        'products',
        OLD.id,
        NOW(),
        json_build_object(
            'name', OLD.name,
            'price', OLD.price::text,
            'deleted_via', 'database_trigger'
        )
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER product_deletion_trigger
    BEFORE DELETE ON products
    FOR EACH ROW
    EXECUTE FUNCTION log_product_deletion();
```

#### Opção 3: Decorator Personalizado

```typescript
// decorators/log-deletion.decorator.ts
import { SetMetadata } from '@nestjs/common';

export const LOG_DELETION_KEY = 'logDeletion';
export const LogDeletion = (entityType: string) => SetMetadata(LOG_DELETION_KEY, entityType);

// interceptors/deletion-log.interceptor.ts
import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable, tap } from 'rxjs';
import { PrismaService } from '../prisma.service';
import { LOG_DELETION_KEY } from '../decorators/log-deletion.decorator';

@Injectable()
export class DeletionLogInterceptor implements NestInterceptor {
  constructor(
    private reflector: Reflector,
    private prisma: PrismaService
  ) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const entityType = this.reflector.get<string>(LOG_DELETION_KEY, context.getHandler());
    
    if (!entityType) {
      return next.handle();
    }

    const request = context.switchToHttp().getRequest();
    const entityId = request.params.id;
    const deletedBy = request.user?.id;

    return next.handle().pipe(
      tap(async () => {
        if (entityId) {
          await this.logDeletion(entityType, entityId, deletedBy);
        }
      })
    );
  }

  private async logDeletion(entityType: string, entityId: string, deletedBy?: string) {
    try {
      await this.prisma.deletionLog.create({
        data: {
          entityType,
          entityId,
          deletedBy,
          metadata: {
            deletedVia: 'decorator-interceptor'
          }
        }
      });
    } catch (error) {
      console.error('Erro ao registrar log de deleção:', error);
    }
  }
}

// Uso no controller
@Delete(':id')
@LogDeletion('users')
@UseInterceptors(DeletionLogInterceptor)
async deleteUser(@Param('id') id: string) {
  return this.userService.delete(id);
}
```

#### Configuração do Middleware (Recomendado)

```typescript
// app.module.ts
import { Module } from '@nestjs/common';
import { PrismaMiddlewareService } from './prisma-middleware.service';

@Module({
  providers: [
    PrismaMiddlewareService,
    // ... outros providers
  ],
})
export class AppModule {}
```

### Limpeza Automática de Logs

```typescript
// cleanup.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from './prisma.service';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class CleanupService {
  private readonly logger = new Logger(CleanupService.name);
  
  constructor(
    private prisma: PrismaService,
    private configService: ConfigService
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_2AM)
  async cleanupOldDeletionLogs() {
    const retentionDays = this.configService.get<number>('SYNC_RETENTION_DAYS', 30);
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);
    
    try {
      const result = await this.prisma.deletionLog.deleteMany({
        where: {
          deletedAt: { lt: cutoffDate }
        }
      });
      
      this.logger.log(`Limpeza concluída: ${result.count} logs de deleção removidos`);
    } catch (error) {
      this.logger.error('Erro na limpeza de logs de deleção:', error);
    }
  }
}
```

## 🎯 Boas Práticas

### ✅ Faça

- Use timestamps UTC (ISO 8601)
- Implemente log de deleção em vez de soft delete
- Use transações para operações de deleção
- Valide o formato do `last_sync`
- Implemente paginação para grandes volumes
- Mantenha logs de sincronização
- Use índices em campos de data
- Valide autenticação e autorização
- Configure limpeza automática de logs antigos
- Use DTOs para validação de entrada
- Implemente tratamento de erros adequado
- **Configure middleware do Prisma para detecção automática de deleções**
- **Use triggers de banco quando necessário para garantir integridade**
- **Monitore performance dos middlewares e triggers**
- **Implemente paginação inteligente baseada no volume de dados**
- **Configure timeouts apropriados para diferentes tamanhos de lote**
- **Use processamento em background para grandes sincronizações**
- **Monitore métricas de performance e ajuste tamanhos de lote**

### ❌ Evite

- DELETE físico sem log de deleção
- Timestamps em timezone local
- Retornar dados sensíveis desnecessários
- Ignorar validação de autenticação
- Queries sem índices em campos de data
- Respostas sem tratamento de erro
- Hardcoding de valores de configuração
- Logs de deleção sem limpeza automática
- **Middleware que impacte significativamente a performance**
- **Triggers complexos que podem causar deadlocks**
- **Log de deleção sem tratamento de erros**
- **Lotes muito grandes que podem causar timeout**
- **Sincronização sem controle de progresso**
- **Processamento síncrono de grandes volumes**
- **Ignorar limitações de memória do dispositivo**

## ⚠️ Considerações Importantes

1. **Log de Deleção**: Use tabela `deletion_logs` em vez de soft delete
2. **Retenção**: Mantenha logs de deleção por pelo menos 30 dias
3. **Transações**: Use transações Prisma para operações de deleção
4. **Paginação**: Considere paginação para grandes volumes de dados
5. **Performance**: Monitore performance das queries de sincronização
6. **Logs**: Mantenha logs detalhados para debugging
7. **Timezone**: Sempre use UTC para timestamps
8. **Validação**: Use DTOs para validar formato do `last_sync`
9. **Índices**: Mantenha índices otimizados para queries de sincronização
10. **Limpeza**: Configure limpeza automática de logs antigos
11. **Detecção Automática**: Configure middleware do Prisma ou triggers para detectar deleções automaticamente
12. **Fallback**: Tenha estratégias de fallback caso o log automático falhe
13. **Monitoramento**: Monitore a criação de logs de deleção para detectar problemas
14. **Performance de Middleware**: Teste o impacto do middleware na performance das operações
15. **Consistência**: Garanta que todas as deleções sejam registradas, independente da origem
16. **Tamanho de Lote**: Ajuste o tamanho dos lotes baseado na capacidade do servidor e cliente
17. **Timeout**: Configure timeouts apropriados para evitar falhas em grandes sincronizações
18. **Memória**: Monitore uso de memória tanto no servidor quanto no cliente
19. **Progresso**: Implemente indicadores de progresso para melhor UX
20. **Recuperação**: Tenha estratégias para recuperar sincronizações interrompidas

## 📦 Estratégias de Processamento em Lotes

### Cenários de Uso

1. **Grandes volumes de dados** (>10.000 registros)
2. **Conexões lentas** ou instáveis
3. **Dispositivos com pouca memória**
4. **Sincronização em background**

### Implementação no Cliente (Flutter/Dart)

```dart
// Exemplo de processamento em lotes no Syncly
class BatchSyncStrategy {
  static const int DEFAULT_BATCH_SIZE = 1000;
  static const int MAX_RETRIES = 3;
  
  Future<void> syncWithPagination({
    String? lastSync,
    int batchSize = DEFAULT_BATCH_SIZE,
    List<String>? entityTypes,
    Function(double)? onProgress,
  }) async {
    int currentPage = 1;
    bool hasMoreData = true;
    int totalProcessed = 0;
    
    while (hasMoreData) {
      try {
        final response = await _fetchBatch(
          page: currentPage,
          limit: batchSize,
          lastSync: lastSync,
          entityTypes: entityTypes,
        );
        
        // Processar dados do lote atual
        await _processBatchData(response.data);
        
        // Atualizar progresso
        if (response.pagination != null) {
          final progress = (currentPage / response.pagination!.totalPages);
          onProgress?.call(progress);
          
          hasMoreData = response.pagination!.hasNextPage;
          totalProcessed += _countRecords(response.data);
        } else {
          hasMoreData = false;
        }
        
        currentPage++;
        
        // Pequena pausa entre lotes para não sobrecarregar
        await Future.delayed(Duration(milliseconds: 100));
        
      } catch (error) {
        await _handleBatchError(error, currentPage);
        break;
      }
    }
    
    print('Sincronização concluída: $totalProcessed registros processados');
  }
  
  Future<SyncResponse> _fetchBatch({
    required int page,
    required int limit,
    String? lastSync,
    List<String>? entityTypes,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (lastSync != null) 'last_sync': lastSync,
      if (entityTypes != null) 'entity_types': entityTypes.join(','),
    };
    
    final uri = Uri.parse('$baseUrl/api/sync/data')
        .replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      return SyncResponse.fromJson(json.decode(response.body));
    } else {
      throw SyncException('Erro na sincronização: ${response.statusCode}');
    }
  }
  
  Future<void> _processBatchData(Map<String, dynamic> data) async {
    // Processar em transações para garantir consistência
    await database.transaction((txn) async {
      // Processar usuários
      if (data['users'] != null) {
        await _processUsers(txn, data['users']);
      }
      
      // Processar produtos
      if (data['products'] != null) {
        await _processProducts(txn, data['products']);
      }
    });
  }
  
  Future<void> _processUsers(Transaction txn, Map<String, dynamic> users) async {
    // Inserir novos usuários
    for (final user in users['created'] ?? []) {
      await txn.insert('users', user);
    }
    
    // Atualizar usuários existentes
    for (final user in users['updated'] ?? []) {
      await txn.update('users', user, where: 'id = ?', whereArgs: [user['id']]);
    }
    
    // Deletar usuários
    for (final userId in users['deleted'] ?? []) {
      await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
    }
  }
  
  int _countRecords(Map<String, dynamic> data) {
    int count = 0;
    for (final entityData in data.values) {
      if (entityData is Map<String, dynamic>) {
        count += (entityData['created']?.length ?? 0) as int;
        count += (entityData['updated']?.length ?? 0) as int;
        count += (entityData['deleted']?.length ?? 0) as int;
      }
    }
    return count;
  }
  
  Future<void> _handleBatchError(dynamic error, int page) async {
    print('Erro no lote $page: $error');
    // Implementar estratégia de retry ou fallback
    // Pode tentar novamente com lote menor ou pular para próximo
  }
}
```

### Otimizações de Performance

```dart
// Configurações otimizadas para diferentes cenários
class SyncConfiguration {
  // Para conexões rápidas e dispositivos potentes
  static const SyncConfig highPerformance = SyncConfig(
    batchSize: 5000,
    maxConcurrentRequests: 3,
    retryAttempts: 2,
    timeoutSeconds: 30,
  );
  
  // Para conexões lentas ou dispositivos limitados
  static const SyncConfig lowResource = SyncConfig(
    batchSize: 500,
    maxConcurrentRequests: 1,
    retryAttempts: 5,
    timeoutSeconds: 60,
  );
  
  // Configuração balanceada (padrão)
  static const SyncConfig balanced = SyncConfig(
    batchSize: 1000,
    maxConcurrentRequests: 2,
    retryAttempts: 3,
    timeoutSeconds: 45,
  );
}

class SyncConfig {
  final int batchSize;
  final int maxConcurrentRequests;
  final int retryAttempts;
  final int timeoutSeconds;
  
  const SyncConfig({
    required this.batchSize,
    required this.maxConcurrentRequests,
    required this.retryAttempts,
    required this.timeoutSeconds,
  });
}
```

### Monitoramento e Métricas

```dart
class SyncMetrics {
  int totalBatches = 0;
  int successfulBatches = 0;
  int failedBatches = 0;
  int totalRecords = 0;
  DateTime? startTime;
  DateTime? endTime;
  
  void startSync() {
    startTime = DateTime.now();
    totalBatches = 0;
    successfulBatches = 0;
    failedBatches = 0;
    totalRecords = 0;
  }
  
  void recordBatchSuccess(int recordCount) {
    successfulBatches++;
    totalRecords += recordCount;
  }
  
  void recordBatchFailure() {
    failedBatches++;
  }
  
  void endSync() {
    endTime = DateTime.now();
  }
  
  Duration get duration => endTime!.difference(startTime!);
  double get successRate => successfulBatches / totalBatches;
  double get recordsPerSecond => totalRecords / duration.inSeconds;
  
  Map<String, dynamic> toJson() => {
    'total_batches': totalBatches,
    'successful_batches': successfulBatches,
    'failed_batches': failedBatches,
    'total_records': totalRecords,
    'duration_seconds': duration.inSeconds,
    'success_rate': successRate,
    'records_per_second': recordsPerSecond,
  };
}
```

## 🔧 Configuração de Ambiente

### Variáveis de Ambiente Recomendadas

```bash
# Configurações de banco de dados
DATABASE_URL="postgresql://username:password@localhost:5432/syncly_db?schema=public"

# Configurações de sincronização
SYNC_MAX_RECORDS_PER_REQUEST=1000
SYNC_MIN_RECORDS_PER_REQUEST=100
SYNC_DEFAULT_PAGE_SIZE=1000
SYNC_MAX_PAGE_SIZE=5000
SYNC_RETENTION_DAYS=30
SYNC_ENABLE_LOGGING=true
SYNC_LOG_LEVEL=info

# Configurações de performance
SYNC_ENABLE_PAGINATION=true
SYNC_BATCH_PROCESSING=true
SYNC_CONCURRENT_REQUESTS=2
SYNC_REQUEST_TIMEOUT=45

# Configurações de autenticação
JWT_SECRET="your-jwt-secret-key"
JWT_EXPIRES_IN="24h"

# Configurações de banco
DB_POOL_SIZE=10
DB_TIMEOUT=30000
DB_MAX_CONNECTIONS=20
```

### Configuração do Módulo NestJS

```typescript
// app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { PrismaModule } from './prisma/prisma.module';
import { SyncModule } from './sync/sync.module';
import { UserModule } from './user/user.module';
import { ProductModule } from './product/product.module';
import { AuthModule } from './auth/auth.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ScheduleModule.forRoot(),
    PrismaModule,
    AuthModule,
    SyncModule,
    UserModule,
    ProductModule,
  ],
})
export class AppModule {}
```

### Monitoramento

- Monitore tempo de resposta das APIs de sincronização
- Acompanhe volume de dados transferidos
- Monitore erros e timeouts
- Implemente alertas para falhas de sincronização

## 📚 Recursos Adicionais

- [Documentação completa do Syncly](README.md)
- [Guia de sincronização incremental](INCREMENTAL_SYNC_GUIDE.md)
- [Exemplos de implementação](examples/)
- [Changelog](CHANGELOG.md)

---

**Desenvolvido para o Syncly** - Sistema de Sincronização para Flutter