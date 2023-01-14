run:
	mix phx.server

routes:
	mix phx.routes

deploy:
	git push gigalixir

fmt:
	mix format

ftm:
	mix format

deploy-force:
	git push -f gigalixir

status:
	gigalixir status

test-offline:
	mix test

test-online:
	mix test --include online