import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CitiesService, CityCount } from './cities.service';

@ApiTags('discovery')
@ApiBearerAuth()
@Controller('cities')
export class CitiesController {
  constructor(private readonly cities: CitiesService) {}

  @Get()
  list(): Promise<CityCount[]> {
    return this.cities.list();
  }
}
