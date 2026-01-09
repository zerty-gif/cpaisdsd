#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                         OUTPUT FUNCTIONS MODULE                           ║
# ║                    Rich/Textual Style Terminal Output                     ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 cpostinstallparrot Project
# Contact: andcs@mailbox.org
#
# ═══════════════════════════════════════════════════════════════════════════════
# MODULE DESCRIPTION
# ═══════════════════════════════════════════════════════════════════════════════
#
#   This module provides Rich/Textual-style terminal output functions.
#   Inspired by the Python Rich library, these functions create visually
#   appealing and consistent terminal output with:
#
#     • Emoji prefixes for quick visual identification
#     • Color-coded message types (error=red, success=green, etc.)
#     • Unicode box-drawing characters for panels and tables
#     • Spinner animations for long-running operations
#
#   FUNCTION CATEGORIES:
#   ─────────────────────
#     1. Message Functions    - success(), error(), warning(), info(), etc.
#     2. Panel Functions      - panel_header(), panel_footer(), separator()
#     3. Table Functions      - table_row()
#     4. Animation Functions  - spinner_start(), spinner_stop()
#     5. Cleanup Handlers     - cleanup() for graceful interruption
#
# ═══════════════════════════════════════════════════════════════════════════════
# DESIGN PHILOSOPHY
# ═══════════════════════════════════════════════════════════════════════════════
#
#   We follow the Rich library's design principles:
#
#   1. SEMANTIC COLORING
#      Colors have meaning: red=error, green=success, yellow=warning
#      Users learn the pattern and can quickly scan output
#
#   2. EMOJI PREFIXES
#      Each message type has a distinctive emoji:
#        ✅ SUCCESS  ❌ ERROR  ⚠️ WARNING  📋 INFO  🔄 PROGRESS  📚 ACADEMIC
#      Provides instant visual recognition even without color
#
#   3. STRUCTURED LAYOUTS
#      Panels and tables organize information clearly
#      Unicode box-drawing creates professional appearance
#
#   4. STDERR FOR ERRORS
#      Error and warning messages go to stderr (>&2)
#      Allows stdout redirection while keeping errors visible
#
# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════════
#
#   Requires: 00_constants.sh (color definitions)
#
#   Color constants used:
#     C_RED, C_GREEN, C_YELLOW, C_BLUE, C_MAGENTA, C_CYAN
#     C_BOLD, C_DIM, C_RESET
#
#######################################

#######################################
# MESSAGE OUTPUT FUNCTIONS
#######################################
#
# These functions provide consistent, semantic terminal output.
# Each function:
#   - Uses an emoji prefix for visual identification
#   - Applies appropriate color for message severity
#   - Includes a bracketed label for clarity
#
# OUTPUT STREAMS:
# ───────────────
#   stdout (default) : success, info, progress, debug, academic
#   stderr (>&2)     : error, warning
#
# This separation allows:
#   ./script.sh > output.log     # Errors still visible
#   ./script.sh 2> errors.log    # Capture only errors
#   ./script.sh &> combined.log  # Capture everything
#
#######################################

#######################################
# success()
#######################################
#
# PURPOSE:
#   Display a success message indicating an operation completed successfully.
#
# VISUAL OUTPUT:
#   ✅ [SUCCESS] Configuration file created
#   └─ Green color indicates positive outcome
#
# USAGE:
#   success "Configuration applied"
#   success "Package installation complete"
#
# PARAMETERS:
#   $* : The message text (all arguments concatenated)
#
# RETURNS:
#   0 (always succeeds)
#
# EXAMPLE:
#   if create_config; then
#       success "Configuration file created successfully"
#   fi
#
#######################################
success() {
    # Echo with color codes:
    # - C_GREEN for the prefix and icon
    # - C_RESET to return to normal text
    # - $* expands to all positional parameters as a single string
    echo -e "${C_GREEN}✅ [SUCCESS]${C_RESET} $*"
}

#######################################
# error()
#######################################
#
# PURPOSE:
#   Display an error message indicating a failure that may require intervention.
#
# VISUAL OUTPUT:
#   ❌ [ERROR] Failed to start DHCP service
#   └─ Red color indicates critical problem
#
# USAGE:
#   error "Failed to write configuration file"
#   error "Service startup failed: $reason"
#
# PARAMETERS:
#   $* : The error message text
#
# STREAM:
#   stderr (>&2) - Errors go to standard error, not standard output.
#   This allows: ./script.sh > output.log (errors still show on terminal)
#
# RETURNS:
#   0 (the function itself succeeds; it reports an error, doesn't cause one)
#
# NOTE:
#   This function reports errors but does NOT exit the script.
#   The caller should handle exit logic if needed.
#
#######################################
error() {
    # Output to stderr (>&2) so errors are visible even when stdout is redirected
    echo -e "${C_RED}❌ [ERROR]${C_RESET} $*" >&2
}

#######################################
# warning()
#######################################
#
# PURPOSE:
#   Display a warning message indicating a potential issue that doesn't
#   prevent operation but should be noted.
#
# VISUAL OUTPUT:
#   ⚠️  [WARNING] Configuration file already exists
#   └─ Yellow color indicates caution
#
# USAGE:
#   warning "Using default DNS servers"
#   warning "Backup file not found, proceeding anyway"
#
# PARAMETERS:
#   $* : The warning message text
#
# STREAM:
#   stderr (>&2) - Warnings go to standard error
#
# RETURNS:
#   0 (always succeeds)
#
# USE CASES:
#   - Non-fatal configuration issues
#   - Missing optional files
#   - Default values being used
#   - Deprecated options detected
#
#######################################
warning() {
    # Note the extra space after ⚠️ for alignment with other prefixes
    echo -e "${C_YELLOW}⚠️  [WARNING]${C_RESET} $*" >&2
}

#######################################
# info()
#######################################
#
# PURPOSE:
#   Display an informational message about status or progress.
#
# VISUAL OUTPUT:
#   📋 [INFO] Installing packages...
#   └─ Blue color for neutral information
#
# USAGE:
#   info "Starting configuration"
#   info "Found 3 scope files"
#
# PARAMETERS:
#   $* : The informational message text
#
# RETURNS:
#   0 (always succeeds)
#
# USE CASES:
#   - Status updates during execution
#   - Announcing next steps
#   - Displaying discovered information
#
#######################################
info() {
    echo -e "${C_BLUE}📋 [INFO]${C_RESET} $*"
}

#######################################
# progress()
#######################################
#
# PURPOSE:
#   Display a progress message for ongoing operations.
#
# VISUAL OUTPUT:
#   🔄 [PROGRESS] Configuring network interface...
#   └─ Cyan color for active operations
#
# USAGE:
#   progress "Installing packages"
#   progress "Writing configuration file"
#
# PARAMETERS:
#   $* : Description of the ongoing operation
#
# RETURNS:
#   0 (always succeeds)
#
# NOTE:
#   Use this BEFORE starting an operation.
#   Follow with success/error when the operation completes.
#
# EXAMPLE:
#   progress "Installing packages"
#   apt-get install -y package
#   success "Packages installed"
#
#######################################
progress() {
    echo -e "${C_CYAN}🔄 [PROGRESS]${C_RESET} $*"
}

#######################################
# debug()
#######################################
#
# PURPOSE:
#   Display debug information for troubleshooting.
#
# VISUAL OUTPUT:
#   🔍 [DEBUG] Variable value: /etc/kea
#   └─ Dim color for less important details
#
# USAGE:
#   debug "Scope file path: $scope_path"
#   debug "Parsed values: network=$network, mask=$mask"
#
# PARAMETERS:
#   $* : The debug information
#
# RETURNS:
#   0 (always succeeds)
#
# NOTE:
#   Currently always displayed. In production, you might want
#   to gate this behind a DEBUG environment variable:
#   [[ "${DEBUG:-}" == "1" ]] && echo -e "..."
#
#######################################
debug() {
    echo -e "${C_DIM}🔍 [DEBUG]${C_RESET} $*"
}

#######################################
# academic()
#######################################
#
# PURPOSE:
#   Display educational/academic notes explaining concepts.
#   These provide context about WHY something is done, referencing
#   RFCs and technical standards.
#
# VISUAL OUTPUT:
#   📚 [ACADEMIC] RFC 2131 Section 4.3.1 specifies the DORA process
#   └─ Magenta color for educational content
#
# USAGE:
#   academic "DHCP uses UDP ports 67 (server) and 68 (client)"
#   academic "This implements RFC 2132 Section 3.8 (DNS servers)"
#
# PARAMETERS:
#   $* : The educational explanation
#
# RETURNS:
#   0 (always succeeds)
#
# DESIGN NOTE:
#   This is a key feature of this script - it's designed as an
#   educational resource. Academic notes explain the reasoning
#   behind configuration decisions, making this script useful
#   for learning, not just execution.
#
#######################################
academic() {
    echo -e "${C_MAGENTA}📚 [ACADEMIC]${C_RESET} $*"
}


#######################################
# PANEL AND TABLE FUNCTIONS
#######################################
#
# RICH-STYLE PANELS
# ═════════════════
#
# Panels are bordered boxes that group related information.
# They use Unicode box-drawing characters for visual appeal.
#
# BOX-DRAWING CHARACTERS USED:
# ┌───────────────────────────────────────────────────────────────────────────┐
# │ Character │ Name                    │ Usage                              │
# ├───────────┼─────────────────────────┼────────────────────────────────────┤
# │     ╭     │ Arc down and right      │ Top-left corner                    │
# │     ╮     │ Arc down and left       │ Top-right corner                   │
# │     ╰     │ Arc up and right        │ Bottom-left corner                 │
# │     ╯     │ Arc up and left         │ Bottom-right corner                │
# │     │     │ Vertical line           │ Left/right borders                 │
# │     ─     │ Horizontal line         │ Top/bottom borders                 │
# │     ├     │ Vertical and right      │ Left T-junction                    │
# │     ┤     │ Vertical and left       │ Right T-junction                   │
# └───────────┴─────────────────────────┴────────────────────────────────────┘
#
# PANEL STRUCTURE:
# ╭──────────────────────────────────────────────────────────────────────────╮
# │                              Panel Title                                 │
# ├──────────────────────────────────────────────────────────────────────────┤
# │ Content line 1                                                           │
# │ Content line 2                                                           │
# ╰──────────────────────────────────────────────────────────────────────────╯
#
#######################################

#######################################
# panel_header()
#######################################
#
# PURPOSE:
#   Draw the top portion of a panel with a centered title.
#
# VISUAL OUTPUT:
#   ╭──────────────────────────────────────────────────────────────────────────╮
#   │                              Panel Title                                 │
#   ├──────────────────────────────────────────────────────────────────────────┤
#
# USAGE:
#   panel_header "Configuration Summary"
#   panel_header "System Information"
#
# PARAMETERS:
#   $1 : The panel title (will be centered)
#
# RETURNS:
#   0 (always succeeds)
#
# IMPLEMENTATION NOTES:
#   - Width is fixed at 70 characters for consistency
#   - Title is centered using calculated padding
#   - Uses printf for precise alignment control
#
#######################################
panel_header() {
    # Extract the title from the first argument
    local title="$1"
    
    # Fixed panel width for consistency across all panels
    local width=70
    
    # Calculate padding to center the title
    # Formula: (total_width - title_length - 2) / 2
    # The -2 accounts for spaces around the title
    local padding=$(( (width - ${#title} - 2) / 2 ))
    
    # Generate the horizontal line (─ repeated 'width' times)
    # tr ' ' '─' replaces spaces with the line character
    local line
    line=$(printf '%*s' "$width" '' | tr ' ' '─')
    
    # Output the panel header
    echo ""  # Blank line before panel for visual separation
    
    # Top border: ╭────────────────╮
    echo -e "${C_BOLD}╭${line}╮${C_RESET}"
    
    # Title line: │    Title    │
    # printf with %*s creates padding of specified width
    printf "${C_BOLD}│${C_RESET}%*s${C_CYAN}%s${C_RESET}%*s${C_BOLD}│${C_RESET}\n" \
        "$padding" "" "$title" "$((width - padding - ${#title}))" ""
    
    # Separator: ├────────────────┤
    echo -e "${C_BOLD}├${line}┤${C_RESET}"
}

#######################################
# panel_footer()
#######################################
#
# PURPOSE:
#   Draw the bottom portion of a panel, closing it visually.
#
# VISUAL OUTPUT:
#   ╰──────────────────────────────────────────────────────────────────────────╯
#
# USAGE:
#   panel_footer
#
# PARAMETERS:
#   None
#
# RETURNS:
#   0 (always succeeds)
#
# NOTE:
#   Must be called after panel_header() to properly close the panel.
#   All table_row() calls should be between header and footer.
#
#######################################
panel_footer() {
    # Fixed width matching panel_header
    local width=70
    
    # Generate the horizontal line
    local line
    line=$(printf '%*s' "$width" '' | tr ' ' '─')
    
    # Bottom border: ╰────────────────╯
    echo -e "${C_BOLD}╰${line}╯${C_RESET}"
    
    echo ""  # Blank line after panel for visual separation
}

#######################################
# table_row()
#######################################
#
# PURPOSE:
#   Display a key-value pair formatted as a table row within a panel.
#
# VISUAL OUTPUT:
#   │ Parameter Name           : Parameter Value                        │
#
# USAGE:
#   table_row "Hostname" "server01"
#   table_row "IP Address" "192.168.100.1"
#
# PARAMETERS:
#   $1 : The label/key (left column)
#   $2 : The value (right column)
#
# RETURNS:
#   0 (always succeeds)
#
# FORMATTING:
#   - Label column: 25 characters, left-aligned
#   - Colon separator in dim color
#   - Value column: 42 characters, left-aligned
#   - Total width: 70 characters (matching panels)
#
#######################################
table_row() {
    # printf format breakdown:
    # %-25s : Left-align label in 25-character field
    # %-42s : Left-align value in 42-character field
    printf "${C_BOLD}│${C_RESET} %-25s ${C_DIM}:${C_RESET} %-42s${C_BOLD}│${C_RESET}\n" "$1" "$2"
}

#######################################
# separator()
#######################################
#
# PURPOSE:
#   Draw a horizontal separator line within a panel.
#   Used to visually divide sections of content.
#
# VISUAL OUTPUT:
#   ├──────────────────────────────────────────────────────────────────────────┤
#
# USAGE:
#   panel_header "Title"
#   table_row "Key1" "Value1"
#   separator
#   table_row "Key2" "Value2"
#   panel_footer
#
# PARAMETERS:
#   None
#
# RETURNS:
#   0 (always succeeds)
#
#######################################
separator() {
    local width=70
    local line
    line=$(printf '%*s' "$width" '' | tr ' ' '─')
    
    # T-junction separators: ├────────────────┤
    echo -e "${C_BOLD}├${line}┤${C_RESET}"
}


#######################################
# SPINNER ANIMATION
#######################################
#
# VISUAL FEEDBACK FOR LONG OPERATIONS
# ═══════════════════════════════════
#
# Spinners provide visual feedback during time-consuming operations
# like package installation or network configuration.
#
# ANIMATION PATTERN:
#   Uses Braille pattern characters for smooth animation:
#   ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
#
#   These characters create a "spinning" dot pattern that cycles
#   smoothly, providing clear indication that work is in progress.
#
# IMPLEMENTATION:
#   The spinner runs in a background subshell process.
#   The main script continues execution while the spinner animates.
#   spinner_stop() kills the background process when done.
#
# TERMINAL CONTROL:
#   \r    : Carriage return (move cursor to start of line)
#   \033[K : Clear from cursor to end of line
#   These allow the spinner to update in place without scrolling.
#
#######################################

# SPINNER_PID: Global variable to track the background spinner process.
#              Set by spinner_start(), used by spinner_stop().
#
SPINNER_PID=""

#######################################
# spinner_start()
#######################################
#
# PURPOSE:
#   Start a spinner animation in the background with a message.
#
# VISUAL OUTPUT:
#   ⠋ Installing packages...
#   (animates through: ⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏)
#
# USAGE:
#   spinner_start "Installing packages"
#   apt-get install -y package
#   spinner_stop
#   success "Packages installed"
#
# PARAMETERS:
#   $1 : The message to display next to the spinner
#
# RETURNS:
#   0 (always succeeds)
#
# SIDE EFFECTS:
#   - Starts a background process
#   - Sets SPINNER_PID global variable
#   - Disowns the process (prevents job control messages)
#
# WARNING:
#   Always call spinner_stop() after the operation completes!
#   Failing to stop the spinner will leave a zombie process.
#
#######################################
spinner_start() {
    local message="$1"
    
    # Braille pattern characters for smooth spinning animation
    # These cycle through to create a "rotating dot" effect
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    
    # Start the spinner in a background subshell
    # The subshell runs an infinite loop until killed
    (
        while true; do
            # Cycle through each character in the spinner pattern
            for (( i=0; i<${#chars}; i++ )); do
                # \r returns to start of line
                # Print spinner character, message, and "..."
                echo -ne "\r${C_CYAN}${chars:$i:1}${C_RESET} ${message}..."
                
                # Short delay between frames (100ms)
                sleep 0.1
            done
        done
    ) &
    
    # Capture the background process ID
    SPINNER_PID=$!
    
    # Disown the process to prevent job control messages
    # This suppresses "[1]+ Done" messages when the process ends
    disown "$SPINNER_PID" 2>/dev/null || true
}

#######################################
# spinner_stop()
#######################################
#
# PURPOSE:
#   Stop the spinner animation and clear the line.
#
# USAGE:
#   spinner_start "Working"
#   do_work
#   spinner_stop
#
# PARAMETERS:
#   None
#
# RETURNS:
#   0 (always succeeds)
#
# SIDE EFFECTS:
#   - Kills the background spinner process
#   - Clears the spinner line from the terminal
#   - Resets SPINNER_PID to empty
#
# SAFETY:
#   - Checks if SPINNER_PID is set and process exists
#   - Uses kill -0 to test if process is running
#   - Waits for process to fully terminate
#   - Safe to call even if spinner wasn't started
#
#######################################
spinner_stop() {
    # Check if SPINNER_PID is set and not empty
    # Also verify the process is still running with kill -0
    if [[ -n "${SPINNER_PID:-}" ]] && kill -0 "$SPINNER_PID" 2>/dev/null; then
        # Send TERM signal to stop the spinner process
        kill "$SPINNER_PID" 2>/dev/null || true
        
        # Wait for the process to fully terminate
        # Prevents zombie processes
        wait "$SPINNER_PID" 2>/dev/null || true
        
        # Clear the spinner line:
        # \r     - Return to start of line
        # \033[K - Clear from cursor to end of line
        echo -ne "\r\033[K"
    fi
    
    # Reset the PID variable
    SPINNER_PID=""
}


#######################################
# CLEANUP AND SIGNAL HANDLING
#######################################
#
# GRACEFUL INTERRUPTION HANDLING
# ══════════════════════════════
#
# When a user presses Ctrl+C (SIGINT) or the script receives SIGTERM,
# we want to:
#   1. Stop any running spinner animation
#   2. Inform the user that the script was interrupted
#   3. Provide guidance on recovery
#   4. Exit with appropriate status code
#
# SIGNAL CODES:
#   SIGINT  (2)  : Interrupt from keyboard (Ctrl+C)
#   SIGTERM (15) : Termination signal (kill command)
#
# EXIT CODES:
#   130 = 128 + 2 (SIGINT)  : Standard exit code for Ctrl+C
#   143 = 128 + 15 (SIGTERM): Standard exit code for kill
#
#######################################

#######################################
# cleanup()
#######################################
#
# PURPOSE:
#   Handle script interruption gracefully.
#   Called automatically when SIGINT or SIGTERM is received.
#
# ACTIONS:
#   1. Stops any running spinner
#   2. Displays warning about partial configuration
#   3. Suggests checking backup files
#   4. Exits with code 130 (interrupted)
#
# USAGE:
#   This function is registered as a signal handler:
#   trap cleanup SIGINT SIGTERM
#
# PARAMETERS:
#   None (called by signal trap)
#
# RETURNS:
#   Does not return - exits the script
#
#######################################
cleanup() {
    # Stop any running spinner to prevent orphaned process
    spinner_stop
    
    # Print blank line for visual separation
    echo ""
    
    # Warn user about potential partial state
    warning "Script interrupted. Partial configuration may have been applied."
    
    # Provide recovery guidance
    info "Check backup files (.bak) to restore previous configuration."
    
    # Exit with code 130 (128 + SIGINT=2)
    # This is the standard exit code for Ctrl+C
    exit 130
}

# Register cleanup() as the signal handler for SIGINT and SIGTERM
# trap 'command' SIGNALS : Run 'command' when SIGNALS are received
trap cleanup SIGINT SIGTERM


#######################################
# MODULE LOAD CONFIRMATION
#######################################
# Uncomment for debugging module loading:
# echo "Module loaded: 01_output.sh (Output Functions)"
