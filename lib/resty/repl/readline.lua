
-- MIT License
-- 
-- Copyright (c) 2017 Aliaksandr Rahalevich
--
-- Modification by JulianDroske
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


local readline_utils = require 'resty.repl.readline_utils'

local no_readline_fallback = function()
	io.write 'No readline found. Fallback to linenoise.\n'
 	local ok, err = pcall(function() require 'linenoise' end)
	if ok then return require 'jurt.readline_linenoise'
		else io.write 'No linenoise found. Fallback mode.\n' end
	return require 'resty.repl.readline_stub'
end

local success, ffi = pcall(function() return require('ffi') end)
if not success then return no_readline_fallback() end

-- from unistd.h:
local R_OK = 4
local W_OK = 2
local F_OK = 0

ffi.cdef[[
	/* libc definitions */
	void* malloc(size_t bytes);
	void free(void *);

	/* stdio.h */
	size_t fwrite(const void *, size_t, size_t, void*);

	/* unistd.h */
	int access(const char *pathname, int mode);

	typedef void rl_vcpfunc_t (char *);

	char *readline (const char *prompt);

	/* basic history handling */
	void add_history(const char *line);
	int write_history (const char *filename);
	int append_history (int nelements, const char *filename);
	int read_history (const char *filename);

	/* completion */
	typedef char **rl_completion_func_t (const char *, int, int);
	typedef char *rl_compentry_func_t (const char *, int);
	typedef char **rl_hook_func_t (const char *, int);
	typedef char *rl_hook_func_t (const char *, int);

	char **rl_completion_matches (const char *, rl_compentry_func_t *);

	const char *rl_basic_word_break_characters;
	rl_completion_func_t *rl_attempted_completion_function;
	char *rl_line_buffer;
	int rl_completion_append_character;
	int rl_completion_suppress_append;
	int rl_attempted_completion_over;

	void rl_callback_handler_install (const char *prompt, rl_vcpfunc_t *lhandler);
	void rl_callback_read_char (void);
	void rl_callback_handler_remove (void);

	void* rl_outstream;

	int rl_set_prompt (const char *prompt);
	int rl_clear_message (void);
	void rl_replace_line (const char *text);
	int rl_message (const char *);
	int rl_delete_text (int start, int end);
	int rl_insert_text (const char *);
	int rl_forced_update_display (void);
	void rl_redisplay (void);
	int rl_point;

	rl_hook_func_t *rl_startup_hook;
	int rl_readline_state;
]]

-- for builds with separate libhistory:
pcall(ffi.load, 'libhistory.so.6')
pcall(ffi.load, 'libhistory.so.7')
pcall(ffi.load, 'libhistory')

local readline_available, clib

-- for linux with libreadline 6.x:
readline_available, clib = pcall(ffi.load, 'libreadline.so.6')

-- for linux with libreadline 7.x:
if not readline_available then
	readline_available, clib = pcall(ffi.load, 'libreadline.so.7')
end

-- for mac:
if not readline_available then
	readline_available, clib = pcall(ffi.load, 'libreadline')
end

if not readline_available then return no_readline_fallback() end

local function history_file_is_writable()
	local history_fn = readline_utils.history_fn()
	local rw_access = bit.bor(R_OK, W_OK)
	local file_exist = 0 == clib.access(history_fn, F_OK)

	if file_exist then
		return 0 == clib.access(history_fn, rw_access)
	else -- check dir
		return 0 == clib.access(readline_utils.home_dir, rw_access)
	end
end

if not history_file_is_writable() then readline_utils.home_dir = '/tmp' end

-- read history from file
clib.read_history(readline_utils.history_fn())

local write = function(text)
	return clib.fwrite(text, #text, 1, clib.rl_outstream)
end

local puts = function(text)
	if nil == text then text = '' else text = tostring(text) end
	return write(text .. '\n')
end

local add_to_history = function(text)
	clib.add_history(text)
	if history_file_is_writable() then
		clib.write_history(readline_utils.history_fn())
	end
end

local teardown = function()
	clib.rl_callback_handler_remove()
end

local function set_attempted_completion_function(callback)
	function clib.rl_attempted_completion_function(word)
		local strword = ffi.string(word)
		local buffer = ffi.string(clib.rl_line_buffer)

		local matches = callback(strword, buffer)

		if not matches then return nil end

		-- if matches is an empty array, tell readline to not call default completion (file)
		clib.rl_attempted_completion_over = 1
		pcall(function() clib.rl_completion_suppress_append = 1 end)

		-- translate matches table to C strings
		-- (there is probably more efficient ways to do it)
		return clib.rl_completion_matches(word, function(_, i)
			local match = matches[i + 1]

			if match then
				-- readline will free the C string by itself, so create copies of them
				local buf = ffi.C.malloc(#match + 1)
				ffi.copy(buf, match, #match + 1)
				return buf
			else
				return ffi.new('void*', nil)
			end
		end)
	end
end

local chars_to_string = function(chars)
	local result = ffi.string(chars)
	ffi.C.free(chars)
	return result
end

local readline = function(...)
	local chars = clib.readline(...)
	local line

	if chars ~= nil then
		line = chars_to_string(chars)
	end

	return line
end

local set_startup_hook = function(f) clib.rl_startup_hook = f end

local _M = setmetatable({
	set_startup_hook = set_startup_hook,
	teardown = teardown,
	puts = puts,
	set_attempted_completion_function = set_attempted_completion_function,
	add_to_history = add_to_history,
}, { __call = function(_, ...) return readline(...) end })

return _M
