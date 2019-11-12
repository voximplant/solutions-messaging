import { Message, User } from '@/types/src/conversations';

export interface UserEvents {
  user: User;
  userId: number;
  initiator: number;
}

export interface MessageEvents {
  message: Message;
  timestamp: number;
  seq: number;
  initiator: number;
}
