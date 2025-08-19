import { JobScheduler } from '../scheduler';

describe('JobScheduler', () => {
  test('should create scheduler instance', () => {
    // Mock environment variable
    process.env['JWT_TOKEN'] = 'test-token';
    
    const scheduler = new JobScheduler();
    expect(scheduler).toBeDefined();
    expect(scheduler.getJobNames()).toEqual([]);
  });

  test('should get initial status', () => {
    process.env['JWT_TOKEN'] = 'test-token';
    
    const scheduler = new JobScheduler();
    const status = scheduler.getStatus();
    
    expect(status).toHaveProperty('totalJobs');
    expect(status).toHaveProperty('runningJobs');
    expect(status).toHaveProperty('jobNames');
    expect(status.totalJobs).toBe(0);
    expect(status.runningJobs).toBe(0);
    expect(status.jobNames).toEqual([]);
  });
});
