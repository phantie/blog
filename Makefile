run:
	mix phx.server

routes:
	mix phx.routes

deploy:
	git push gigalixir

fmt:
	mix format

deploy-force:
	git push -f gigalixir

status:
	gigalixir status

test-local:
	mix test