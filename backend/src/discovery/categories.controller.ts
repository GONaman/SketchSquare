import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Roles } from '../auth/decorators';
import {
  type AuthUser,
  CurrentUser,
} from '../common/decorators/current-user.decorator';
import { Page } from '../common/pagination';
import {
  AdminCategoryRequestView,
  CategoriesService,
  CategoryRequestView,
  CategoryView,
} from './categories.service';
import {
  CategoryRequestsQueryDto,
  CreateCategoryRequestDto,
} from './dto/category.dto';

@ApiTags('discovery')
@ApiBearerAuth()
@Controller()
export class CategoriesController {
  constructor(private readonly categories: CategoriesService) {}

  @Get('categories')
  list(): Promise<CategoryView[]> {
    return this.categories.list();
  }

  @Post('category-requests')
  request(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateCategoryRequestDto,
  ): Promise<CategoryRequestView> {
    return this.categories.request(user.id, dto.name);
  }

  @Get('admin/category-requests')
  @Roles('ADMIN')
  listRequests(
    @Query() query: CategoryRequestsQueryDto,
  ): Promise<Page<AdminCategoryRequestView>> {
    return this.categories.listRequests(query);
  }

  @Post('admin/category-requests/:id/approve')
  @Roles('ADMIN')
  @HttpCode(HttpStatus.OK)
  approve(
    @CurrentUser() admin: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.categories.approve(admin.id, id);
  }

  @Post('admin/category-requests/:id/reject')
  @Roles('ADMIN')
  @HttpCode(HttpStatus.OK)
  reject(
    @CurrentUser() admin: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.categories.reject(admin.id, id);
  }
}
