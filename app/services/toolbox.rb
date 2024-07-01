class Toolbox < SDK
  def self.descendants
    gmail_active = Feature.google_tools? && Current.user&.gmail_credential || nil
    tasks_active = Feature.google_tools? && Current.user&.google_tasks_credential || nil
    test_env = Rails.env.test? || nil
    [
      test_env && Toolbox::HelloWorld,
      Toolbox::OpenMeteo,
      Toolbox::Dalle,
      Toolbox::Memory,
      gmail_active && Toolbox::Gmail,
      tasks_active && Toolbox::GoogleTasks,
    ].compact
  end

  def self.call(name, args)
    kname, method = name.split("_", 2)
    klass = Toolbox.descendants.find { |k| k.to_s.downcase == "toolbox::#{kname}" }
    raise "'#{kname}' does not match a class which is a descendant of SDK. Your function name should be prepended with the class name." if klass.nil?
    instance = klass.new
    raise "'#{method} does not exist on this class" if klass.functions.exclude?(method.to_sym)
    parameters = {} # arguments are what OpenAI calls them, parameters are what the ruby method expects
    allowed_args = klass.formatted_function_parameters_with_types(method).keys # args may include hallucinations

    args.stringify_keys.slice(*allowed_args).each do |arg, val|
      parameters[ klass.argument_to_parameter(method, arg) ] = val
    end

    instance.public_send(method, **parameters)
  end

  class << self
    def method_descriptions
      (@method_descriptions ||= {}).symbolize_keys
    end

    def describe(method_name, description)
      (@method_descriptions ||= {})[method_name] = description.gsub("\n", " ")
    end

    def description(method_name)
      (@method_descriptions ||= {})[method_name] || default_description_for(method_name)
    end

    def default_description_for(name)
      name.to_s.split("_").join(" ").capitalize + " given " +
        self.formatted_function_required_parameters(name).to_sentence
    end
  end

  def self.tools
    if self == Toolbox
      descendants.map(&:function_tools).flatten
    else
      function_tools
    end
  end

  private

  def self.function_tools
    functions.map do |name|
      {
        type: "function",
        function: {
          name: "#{self.to_s.downcase.remove('toolbox::')}_#{name}",
          description: description(name),
          parameters: {
            type: "object",
            properties: formatted_function_parameters_with_types(name),
            required: formatted_function_required_parameters(name),
          }
        }
      }
    end
  end

  def self.functions
    self.instance_methods(false) - Toolbox.instance_methods
  end

  def self.function_parameters(name)
    self.instance_method(name).parameters.map(&:second)
  end

  def self.formatted_function_parameters_with_types(name)
    function_parameters(name).map { |param| formatted_param_properties(param) }.to_h
  end

  def self.formatted_param_properties(param)
    raise "The param '#{param}' is not properly named for the type to be inferred (e.g. is_child, age_num, name_str)" if param.to_s.exclude?('_')

    case param.to_s.split('_')
    in first, *name  if first == "is"
      [ name.join('_'), { type: "boolean" } ]
    in name, "enum", *values
      if values.first.to_i.to_s == values.first
        type = "number"
        values = values.map(&:to_i)
      else
        type = "string"
      end

      [ name, { type: type, enum: values } ]
    in *name, last  if last == "s"
      [ name.join('_'), { type: "string" } ]
    in *name, last  if last == "i"
      [ name.join('_'), { type: "integer" } ]
    in *name, last  if last == "f"
      [ name.join('_'), { type: "number" } ]
    else
      raise "Unable to infer type for parameter '#{param}'"
    end
  end

  def self.formatted_function_required_parameters(name)
    params = self.instance_method(name).parameters
    not_named = params.map(&:first) - [:keyreq, :key]
    raise "Your method '#{name}' needs to use named parameters." if not_named.present?

    params.select { |p| p.first == :keyreq }.map do |_, param|
      formatted_param_properties(param).first
    end
  end

  def self.argument_to_parameter(method, argument)
    @@argument_to_parameter ||= {}
    @@argument_to_parameter[method] ||= {}
    if @@argument_to_parameter[method].empty?
      @@argument_to_parameter[method]

      self.instance_method(method).parameters.map(&:second).each do |param|
        arg = formatted_param_properties(param).first
        @@argument_to_parameter[method][arg] = param
      end
    end
    @@argument_to_parameter[method][argument]
  end
end
