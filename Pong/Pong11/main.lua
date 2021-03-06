--[[
	Credits to Colton Ogden from HarvardX CS50

	Originally programmed by Atari in 1972. Features 2 paddles controlled by players,
	with the goal of getting  the ball pass through the opponents edge. First to 10
	points wins.

	This version is built to more closely resemble the NES than the original Pong
	machines or the Atari 2600 in terms of resolution, though in widescreen (16:9)
	so it looks nicer on modern systems.
]]

-- Constants
WINDOW_WIDTH = 1280	--X
WINDOW_HEIGHT = 720	--Y

-- Still modern in appearance but still has that retro look on ti
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

Class = require 'class' -- https://github.com/vrld/hump/blob/master/class.lua
push = require 'push'	-- https://github.com/Ulydev/push

-- Global variable
require 'Ball'
require 'Paddle'

function love.load()
	-- Random number generator
	math.randomseed(os.time())	-- Unix epoch time

	love.window.setTitle('Pong')	-- Sets the title of the app
	
	-- Perfect pixels upscalling and downscalling, simulating a retro feel
	love.graphics.setDefaultFilter('nearest', 'nearest')

	--[[
		Loads a font file into the memory, setting it to a specific size,
		and store it to an object we can use globally
	]]
	smallFont = love.graphics.newFont('font.TTF', 8)
	scoreFont = love.graphics.newFont('font.TTF', 32)
	victoryFont = love.graphics.newFont('font.TTF', 24)

	--[[
		Adding audio
		Type:
			Static:	preserved in memory
			Stream: from disk if neede
	]]
	sounds = {
		['paddle_hit'] = love.audio.newSource('paddle_hit.wav', 'static'),
		['point_score'] = love.audio.newSource('point_score.wav', 'static'),	
		['wall_hit'] = love.audio.newSource('wall_hit.wav', 'static')
	}

	player1Score = 0
	player2Score = 0

	servingPlayer = math.random(2) == 1 and 1 or 2

	winningPlayer = 0	

	paddle1 = Paddle(5, 20, 5, 20)
	paddle2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)
	ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 5, 5)

	if servingPlayer == 1 then
		ball.dx = 100
	elseif servingPlayer == 2 then
		ball.dx = -100
	end

	gameState = 'start' -- Game state
	
	--[[
		Runs when the game first starts up
		Initialize the  game
	]]
	push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, 
	{
		fullscreen = false,
		vsync = true,
		resizable = false
	})
end

function love.update(dt)	-- dt or delta time allows to move things independently
	if gameState == 'play' then

		if ball.x <= 0 then
			player2Score = player2Score + 1	-- Increment score
			ball:reset()	-- Next round
			ball.dx = 100
			servingPlayer = 1
			sounds['point_score']:play()
			gameState = 'serve'

			if player2Score >= 10 then
				gameState = 'victory'
				winningPlayer = 2
			else
				gameState = 'serve'
			end
		end

		if ball.x >= VIRTUAL_WIDTH - 4 then
			player1Score = player1Score + 1
			ball:reset()
			ball.dx = -100
			servingPlayer = 2
			sounds['point_score']:play()
			gameState = 'serve'

			if player1Score >= 10 then
				gameState = 'victory'
				winningPlayer = 1
			else
				gameState = 'serve'
			end
		end

		paddle1:update(dt)
		paddle2:update(dt)

		if ball:collides(paddle1) then
			ball.dx = -ball.dx	-- Deflect the ball to the right
			sounds['paddle_hit']:play()
		end

		if ball:collides(paddle2) then
			ball.dx = -ball.dx	-- Deflect the ball to the left
			sounds['paddle_hit']:play()
		end

		if ball.y <= 0 then
			ball.dy = -ball.dy	-- Deflect the ball down
			ball.y = 0
			sounds['wall_hit']:play()
		end

		if ball.y >= VIRTUAL_HEIGHT - 4 then
			ball.dy = -ball.dy	-- Deflect the ball up
			ball.y = VIRTUAL_HEIGHT - 4
			sounds['wall_hit']:play()
		end

		if love.keyboard.isDown('w') then	-- Returns true or false if the specified key is currently held downs
			paddle1.dy = -PADDLE_SPEED
		elseif love.keyboard.isDown('s') then
			paddle1.dy = PADDLE_SPEED
		else
			paddle1.dy = 0
		end

		if love.keyboard.isDown('up') then
			paddle2.dy = -PADDLE_SPEED	
		elseif love.keyboard.isDown('down') then
			paddle2.dy = PADDLE_SPEED
		else
			paddle2.dy = 0
		end

		ball:update(dt)
	end
end


-- Executes whenever a key is pressed
function love.keypressed(key)

	-- Keys accessed by string name
	if key == 'escape' then
		love.event.quit()	-- Terminates the application
	elseif key == 'enter' or key == 'return' then
		if gameState == 'start' then
			gameState = 'serve'
		elseif gameState == 'serve' then
			gameState = 'play'
		elseif gameState == 'victory' then
			gameState = 'start'
			player1Score = 0
			player2Score = 0
		end
	end
end

-- Called update by LOVE, used to draw anything on the screen, updated or otherwise
function love.draw()
	
	-- Begin rendering at virtual resolution
	push:apply('start')

	-- Sets the background color
	love.graphics.clear(38/255, 70/255, 83/255, 1)

	--[[
		Draws a rectangle choosing whatever the active color is
		Color can be set by love.graphics.setColor()
		Fill is a filled shape
		Line is a hollow shapa
	]]
	love.graphics.setColor(248/255, 249/255, 250/255, 1)
	ball:render()

	paddle1:render()
	paddle2:render()
	
	love.graphics.setFont(smallFont)

	if gameState == 'start' then
		love.graphics.printf("Welcome to Pong!", 0, 20,VIRTUAL_WIDTH, 'center')
		love.graphics.printf("Press enter to Play!", 0, 32,VIRTUAL_WIDTH, 'center')
	elseif gameState == 'serve' then
		love.graphics.printf("Player " .. tostring(servingPlayer) .. "'s turn!", 0, 20,VIRTUAL_WIDTH, 'center')
		love.graphics.printf("Press Enter to Serve", 0, 32,VIRTUAL_WIDTH, 'center')
	elseif gameState == 'victory' then	
		love.graphics.setFont(victoryFont)
		love.graphics.printf("Player " .. tostring(winningPlayer) .. " wins!", 0, 10, VIRTUAL_WIDTH, 'center')	-- Draw a victory message
		love.graphics.setFont(smallFont)
		love.graphics.printf("Press Enter to Serve", 0, 42, VIRTUAL_WIDTH, 'center')
	elseif gameState == 'play' then
		-- No UI message to display in play
	end
	
	displayScore()

	displayFPS()

	-- End rendering at virtual resolution
	push:apply('end')
end

function displayFPS( ... )
	love.graphics.setColor(0, 1, 0, 1)
	love.graphics.setFont(smallFont)
	love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), -- Returns the current FPS of the app making it easier to monitor when printed
						40, 20)
	love.graphics.setColor(1, 1, 1, 1)
end

function displayScore( ... )
	love.graphics.setFont(scoreFont)	-- Active font
	love.graphics.print(player1Score, VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)	-- Print player 1 score
	love.graphics.print(player2Score, VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)	-- Print player 2 score
end

