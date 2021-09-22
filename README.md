# Shipyard CircleCI Orb

[![CircleCI Build Status](https://circleci.com/gh/shipyardbuild/circleci-orb.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/shipyardbuild/circleci-orb) [![CircleCI Orb Version](https://badges.circleci.com/orbs/shipyard/shipyard.svg)](https://circleci.com/orbs/registry/orb/shipyard/shipyard) [![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/shipyardbuild/circleci-orb/master/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)

Use Shipyard with CircleCI to run CircleCI jobs on Staging Environments automatically deployed by Shipyard, authenticating into them via a bypass token. 

This orb connects with Shipyard during a CircleCI job, fetching necessary environment variables in order to run e2e tests where authentication via OAuth is normally required.


## Resources

[Shipyard Documentation](https://docs.shipyard.build/docs/)
