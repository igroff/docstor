SHELL=/bin/bash
.PHONY: watch test pass lint clean

watch:
	STORAGE_PATH=`pwd`/tmp/storage DEBUG=true supervisor --ignore "./test"  -e ".coffee|.js" ./server.coffee


test: lint 
	./test/run.sh ${TEST_NAME}

pass/%:
	cp test/results/$(subst pass/,,$@) test/expected/$(subst pass/,,$@)

show/%:
	cat test/results/$(subst show/,,$@)

lint:
	find -X . -name '*.coffee' | grep -v node_modules | xargs ./node_modules/.bin/coffeelint -f ./etc/coffeelint.conf
	find -X ./src -name '*.js' | grep -v node_modules | xargs ./node_modules/.bin/jshint 

clean:
	rm -rf ./node_modules/
