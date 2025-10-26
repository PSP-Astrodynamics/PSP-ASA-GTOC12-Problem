function varargout = uq_eval_uq_sse(current_model,X)

[varargout{1:nargout}] = evalSSE(current_model.SSE,X);