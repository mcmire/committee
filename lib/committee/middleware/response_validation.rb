module Committee::Middleware
  class ResponseValidation < Base
    def initialize(app, options={})
      super
      @raise = options[:raise]
    end

    def handle(request)
      status, headers, response = @app.call(request.env)
      link = @router.find_request_link(request)

      if link
        response_validator = Committee::ResponseValidator.new(link)
        full_body = ""
        response.each do |chunk|
          full_body << chunk
        end
        data = MultiJson.decode(full_body)
        response_validator.call(status, headers, data)
      end

      [status, headers, response]
    rescue Committee::InvalidResponse
      raise if @raise
      render_error(500, :invalid_response, $!.message)
    rescue MultiJson::LoadError
      raise Committee::InvalidResponse if @raise
      render_error(500, :invalid_response, "Response wasn't valid JSON.")
    end
  end
end
