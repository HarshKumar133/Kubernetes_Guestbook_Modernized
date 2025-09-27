<?php
/**
 * Kubernetes Guestbook Modernized - Frontend Application
 * A modernized guestbook application with Redis backend
 */

// Start session
session_start();

// Configuration
$redis_host = getenv('REDIS_HOST') ?: 'redis';
$redis_port = getenv('REDIS_PORT') ?: 6379;
$redis_password = getenv('REDIS_PASSWORD') ?: '';

// Redis connection
try {
    $redis = new Redis();
    $redis->connect($redis_host, $redis_port);
    
    if (!empty($redis_password)) {
        $redis->auth($redis_password);
    }
    
    // Test connection
    $redis->ping();
} catch (Exception $e) {
    error_log("Redis connection failed: " . $e->getMessage());
    $redis = null;
}

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['message'])) {
    $message = trim($_POST['message']);
    $name = trim($_POST['name'] ?? 'Anonymous');
    
    if (!empty($message) && $redis) {
        $entry = [
            'name' => htmlspecialchars($name, ENT_QUOTES, 'UTF-8'),
            'message' => htmlspecialchars($message, ENT_QUOTES, 'UTF-8'),
            'timestamp' => time(),
            'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown'
        ];
        
        try {
            $redis->lpush('guestbook:entries', json_encode($entry));
            $redis->ltrim('guestbook:entries', 0, 99); // Keep only last 100 entries
            $_SESSION['success'] = 'Message added successfully!';
        } catch (Exception $e) {
            error_log("Failed to save message: " . $e->getMessage());
            $_SESSION['error'] = 'Failed to save message. Please try again.';
        }
    }
    
    // Redirect to prevent form resubmission
    header('Location: ' . $_SERVER['PHP_SELF']);
    exit;
}

// Get messages from Redis
$messages = [];
if ($redis) {
    try {
        $raw_messages = $redis->lrange('guestbook:entries', 0, -1);
        foreach ($raw_messages as $raw_message) {
            $messages[] = json_decode($raw_message, true);
        }
        $messages = array_reverse($messages); // Show newest first
    } catch (Exception $e) {
        error_log("Failed to retrieve messages: " . $e->getMessage());
    }
}

// Get status information
$status = [
    'redis_connected' => $redis !== null,
    'message_count' => count($messages),
    'server_time' => date('Y-m-d H:i:s'),
    'php_version' => PHP_VERSION,
    'redis_version' => $redis ? $redis->info()['redis_version'] : 'Unknown'
];
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kubernetes Guestbook Modernized</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .header p {
            font-size: 1.1em;
            opacity: 0.9;
        }
        
        .content {
            padding: 30px;
        }
        
        .form-section {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
        }
        
        .form-group input,
        .form-group textarea {
            width: 100%;
            padding: 12px;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            font-size: 16px;
            transition: border-color 0.3s ease;
        }
        
        .form-group input:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #4facfe;
        }
        
        .form-group textarea {
            resize: vertical;
            min-height: 100px;
        }
        
        .btn {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s ease;
        }
        
        .btn:hover {
            transform: translateY(-2px);
        }
        
        .messages-section {
            margin-top: 30px;
        }
        
        .message {
            background: white;
            border: 1px solid #e9ecef;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 15px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }
        
        .message-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        
        .message-name {
            font-weight: 600;
            color: #4facfe;
        }
        
        .message-time {
            color: #6c757d;
            font-size: 0.9em;
        }
        
        .message-content {
            color: #333;
            line-height: 1.6;
        }
        
        .status {
            background: #e3f2fd;
            border: 1px solid #bbdefb;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 20px;
        }
        
        .status-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 5px;
        }
        
        .status-item:last-child {
            margin-bottom: 0;
        }
        
        .status-label {
            font-weight: 600;
            color: #1976d2;
        }
        
        .status-value {
            color: #333;
        }
        
        .alert {
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        
        .alert-success {
            background: #d4edda;
            border: 1px solid #c3e6cb;
            color: #155724;
        }
        
        .alert-error {
            background: #f8d7da;
            border: 1px solid #f5c6cb;
            color: #721c24;
        }
        
        .no-messages {
            text-align: center;
            color: #6c757d;
            font-style: italic;
            padding: 40px;
        }
        
        @media (max-width: 600px) {
            .container {
                margin: 10px;
                border-radius: 10px;
            }
            
            .header {
                padding: 20px;
            }
            
            .header h1 {
                font-size: 2em;
            }
            
            .content {
                padding: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Kubernetes Guestbook Modernized</h1>
            <p>Enterprise-grade guestbook application with Redis backend</p>
        </div>
        
        <div class="content">
            <!-- Status Information -->
            <div class="status">
                <div class="status-item">
                    <span class="status-label">Redis Status:</span>
                    <span class="status-value"><?= $status['redis_connected'] ? '✅ Connected' : '❌ Disconnected' ?></span>
                </div>
                <div class="status-item">
                    <span class="status-label">Messages:</span>
                    <span class="status-value"><?= $status['message_count'] ?></span>
                </div>
                <div class="status-item">
                    <span class="status-label">Server Time:</span>
                    <span class="status-value"><?= $status['server_time'] ?></span>
                </div>
                <div class="status-item">
                    <span class="status-label">PHP Version:</span>
                    <span class="status-value"><?= $status['php_version'] ?></span>
                </div>
                <div class="status-item">
                    <span class="status-label">Redis Version:</span>
                    <span class="status-value"><?= $status['redis_version'] ?></span>
                </div>
            </div>
            
            <!-- Flash Messages -->
            <?php if (isset($_SESSION['success'])): ?>
                <div class="alert alert-success">
                    <?= $_SESSION['success'] ?>
                </div>
                <?php unset($_SESSION['success']); ?>
            <?php endif; ?>
            
            <?php if (isset($_SESSION['error'])): ?>
                <div class="alert alert-error">
                    <?= $_SESSION['error'] ?>
                </div>
                <?php unset($_SESSION['error']); ?>
            <?php endif; ?>
            
            <!-- Message Form -->
            <div class="form-section">
                <h2>📝 Add a Message</h2>
                <form method="POST" action="">
                    <div class="form-group">
                        <label for="name">Name:</label>
                        <input type="text" id="name" name="name" placeholder="Your name (optional)" value="<?= htmlspecialchars($_POST['name'] ?? '') ?>">
                    </div>
                    <div class="form-group">
                        <label for="message">Message:</label>
                        <textarea id="message" name="message" placeholder="Write your message here..." required><?= htmlspecialchars($_POST['message'] ?? '') ?></textarea>
                    </div>
                    <button type="submit" class="btn">Send Message</button>
                </form>
            </div>
            
            <!-- Messages Display -->
            <div class="messages-section">
                <h2>💬 Guest Messages</h2>
                <?php if (empty($messages)): ?>
                    <div class="no-messages">
                        No messages yet. Be the first to leave a message!
                    </div>
                <?php else: ?>
                    <?php foreach ($messages as $message): ?>
                        <div class="message">
                            <div class="message-header">
                                <span class="message-name"><?= $message['name'] ?></span>
                                <span class="message-time"><?= date('M j, Y g:i A', $message['timestamp']) ?></span>
                            </div>
                            <div class="message-content">
                                <?= nl2br($message['message']) ?>
                            </div>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>
    </div>
</body>
</html>
