import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService implements OnModuleInit {
  private client: SupabaseClient;

  constructor(private readonly config: ConfigService) {}

  onModuleInit() {
    this.client = createClient(
      this.config.getOrThrow<string>('supabase.url'),
      this.config.getOrThrow<string>('supabase.serviceRoleKey'),
      { auth: { persistSession: false } },
    );
  }

  get db(): SupabaseClient {
    return this.client;
  }
}
