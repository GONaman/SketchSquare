import { INestApplication, Controller, Post, Body } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { IsEmail, IsInt, Min } from 'class-validator';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';

class DemoDto {
  @IsEmail() email!: string;
  @IsInt() @Min(1) qty!: number;
}

@Controller('__demo')
class DemoController {
  @Post()
  create(@Body() dto: DemoDto) {
    return dto;
  }
}

describe('Health + error shape (e2e)', () => {
  let app: INestApplication<App>;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
      controllers: [DemoController],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /health reports db, redis and s3 as up', async () => {
    const res = await request(app.getHttpServer()).get('/health').expect(200);
    expect(res.body).toEqual({
      status: 'ok',
      checks: { db: 'up', redis: 'up', s3: 'up' },
    });
  });

  it('unknown route returns the contract error shape', async () => {
    const res = await request(app.getHttpServer()).get('/nope').expect(404);
    const { error } = res.body as { error: { code: string; message: string } };
    expect(error.code).toBe('NOT_FOUND');
    expect(typeof error.message).toBe('string');
  });

  it('DTO validation failures are 400 VALIDATION_ERROR with field details', async () => {
    const res = await request(app.getHttpServer())
      .post('/__demo')
      .send({ email: 'nope', qty: 0, extra: 1 })
      .expect(400);
    const { error } = res.body as {
      error: { code: string; details: { fields: Record<string, string[]> } };
    };
    expect(error.code).toBe('VALIDATION_ERROR');
    expect(Object.keys(error.details.fields)).toEqual(
      expect.arrayContaining(['email', 'qty', 'extra']),
    );
  });
});
