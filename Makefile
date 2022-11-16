run:
	mix phx.server

routes:
	mix phx.routes

deploy:
	git push gigalixir

deploy_force:
	git push -f gigalixir

status:
	gigalixir status

test:
	mix test