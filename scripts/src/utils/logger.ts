import chalk from 'chalk';

export interface LogOptions {
  prefix?: string;
  timestamp?: boolean;
  level?: 'info' | 'warn' | 'error' | 'success';
}

export const logger = {
  info: (message: string, options: LogOptions = {}) => {
    console.log(chalk.blue('ℹ'), message);
  },
  
  warn: (message: string, options: LogOptions = {}) => {
    console.log(chalk.yellow('⚠'), message);
  },
  
  error: (message: string, options: LogOptions = {}) => {
    console.error(chalk.red('✖'), message);
  },
  
  success: (message: string, options: LogOptions = {}) => {
    console.log(chalk.green('✔'), message);
  }
};