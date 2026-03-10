export type ApiResponse<T = object> = {
  success: boolean;
  data?: T;
  error?: string;
};
