## BASIC INFO
LANG_CODE="en"
LANGUAGE_NAME="English"
LANGUAGE_NAME_EN="English"

# TEXT CODES (1000-1999) - UI ELEMENTS
TXT_001000="Continue"
TXT_001001="OK"
TXT_001002="Cancel"
TXT_001003="Exit"
TXT_001101="Yes"
TXT_001102="No"
TXT_001103="Back"
TXT_001104="Next"

# MESSAGE CODES (2000-2999) - USER MESSAGES
MSG_002000="Operation completed"
MSG_002100="Success"
MSG_002101="Operation completed successfully"
MSG_002200="Processing..."
MSG_002300="Warning"

# TYPE CODES (3000-3999) - CATEGORIES
TYPE_003000="General"
TYPE_003100="Configuration"
TYPE_003200="Directory"
TYPE_003300="File"
TYPE_003400="Network"
TYPE_003500="System"

# ERROR CODES (4000-4999) - ERROR MESSAGES
ERR_004000="An error occurred"
ERR_004100="Configuration error"
ERR_004200="Directory error"
ERR_004300="File error"
ERR_004400="Network error"
ERR_004500="System error"

# LOGGING CODES (5000-5999) - LOG FILES
LOG_005000="Event logged"
LOG_005100="Application started"
LOG_005101="Application shutdown"
LOG_005200="Configuration loaded"
LOG_005201="Configuration saved"
LOG_005300="File processed"
LOG_005301="File created"
LOG_005302="File deleted"

# CONFIGURATION CODES (6000-6999) - CONFIG UI
CFG_006000="Configuration"
CFG_006100="Settings"
CFG_006101="General settings"
CFG_006102="Network settings"
CFG_006103="Security settings"
CFG_006200="Setup wizard"
CFG_006201="Welcome to setup"
CFG_006202="Setup completed"

# HELP CODES (7000-7999) --help OUTPUT
HELP_007000="Help"
HELP_007100="Usage"
HELP_007101="Syntax"
HELP_007102="Parameters"
HELP_007103="Options"
HELP_007200="Examples"
HELP_007300="Description"

# PROGRESS CODES (8000-8999) - PROGRESS STATUS
PROG_008000="Progress"
PROG_008100="Installing..."
PROG_008101="Downloading..."
PROG_008102="Processing..."
PROG_008104="Initializing..."
PROG_008200="Complete"
PROG_008201="Installation complete"
PROG_008202="Download complete"


# INPUT CODES (9000-9999) - USER INPUT PROMPTS
INPUT_009000="Input required"
INPUT_009100="Enter value"
INPUT_009101="Enter path"
INPUT_009102="Enter name"
INPUT_009200="Confirmation"
INPUT_009201="Are you sure?"
INPUT_009202="Confirm deletion"


# MENU CODES (A000-A999) - MENU SYSTEM (hex für 10. Gruppe)
MENU_010000="Menu"
MENU_010100="Main menu"
MENU_010101="Settings menu"
MENU_010102="Tools menu"
MENU_010200="Select option"
MENU_010201="Navigation"

CODE_META_MAP=(
  # UI Texts (010000–019999)
  [001]="TXT:Unknown text"
  [002]="MSG:Unknown message"
  [003]="TYPE:Unknown type"

  # Errors, Logging, Config (040000–069999)
  [004]="ERR:Unknown error"
  [005]="LOG:Unknown log event"
  [006]="CFG:Unknown configuration"

  # Help, Progress, Input, Menu (070000–100000)
  [007]="HELP:Unknown help topic"
  [008]="PROG:Unknown progress"
  [009]="INPUT:Unknown input"
  [010]="MENU:Unknown menu"
)
