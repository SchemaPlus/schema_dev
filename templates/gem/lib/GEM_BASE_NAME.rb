require 'schema_plus/core'

require_relative '%GEM_BASE_NAME%/version'

# Load any mixins to ActiveRecord modules, such as:
#
#require_relative '%GEM_BASE_NAME%/active_record/base'

# Load any middleware, such as:
#
# require_relative '%GEM_BASE_NAME%/middleware/model'

SchemaMonkey.register %GEM_MODULE%
