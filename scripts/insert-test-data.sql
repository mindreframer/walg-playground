-- Insert test data for backup testing
INSERT INTO test_data (name) VALUES 
    ('Test record for backup 1'),
    ('Test record for backup 2'),
    ('Test record for backup 3'),
    ('Test record for backup 4'),
    ('Test record for backup 5');

-- Create additional test table
CREATE TABLE IF NOT EXISTS backup_test (
    id SERIAL PRIMARY KEY,
    description TEXT,
    value INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO backup_test (description, value) VALUES 
    ('First test entry', 100),
    ('Second test entry', 200),
    ('Third test entry', 300);

-- Show current data
SELECT 'test_data table:' as info;
SELECT * FROM test_data ORDER BY id DESC LIMIT 5;

SELECT 'backup_test table:' as info;
SELECT * FROM backup_test ORDER BY id DESC LIMIT 5; 