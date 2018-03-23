# AutoPOOL
AutoPOOl is a fun iOS application I built to solve an incredibly significant painpoint in today’s society: the highly volatile prices of UberPOOL rides.

AutoPOOL sends users automatic push notifications containing UberPOOL price updates (pulled from the Uber API) at time intervals they set. Once the price is in the user’s desired range, Auto-POOL alerts the user with a fun pokemon-themed notifications.

I developed AutoPOOL in Swift, and used Google's App Engine to schedule cron jobs and send push notifications.

### The Problem

#### Born out of Pain

Through large amounts of very scientific research, UberPOOL prices were found to rise and fall upwards of 100% in very short periods of time.

It was reported from a reliable source (definitely not me) that a ride from San Mateo, CA to Mountain View, CA at 5:00pm would cost $25, and then not 5 minutes later cost only $11.50.

The huge swings in prices began to cause severe migraines in many UberPOOL users (again, not me).

### The Solution

#### Set and Forget
AutoPOOL sends users automatic price alerts at intervals they specify in fun pokemon-themed messages. Epidemic Averted.

#### Wild UberPOOL was caught!
Once the UberPOOL price is in the user's desired range, the user will receive a notification with a special pokemon-themed catchphrase.

The user can then book an uber directly in the application.

##Dependencies

####CocoaPods

CocoaPods is a tool that manages library dependencies for XCode projects.

In a nutshell, CocoaPods resolves dependencies between external libraries, fetches library source code, and links it together in an Xcode workspace to build your project. For additional detail on CocoaPods, please visit: https://guides.cocoapods.org/using/getting-started.html.

####Google App Engine

Google App Engine is a cloud platform which makes standing up mobile backends very easy. AutoPOOL uses App Engine to schedule cron jobs.

####Firebase

Firebase is a suite of Google products to help mobile developers with analytics, reporting, and support. AutoPOOL uses Firebase's simple push notification feature.

####Google MAPS API
AutoPOOL integrates with Google MAPS  to set the user's pick-up and drop-off locations. Google MAPS is a widely used, intuitive mapping tool. No need to reinvent the wheel.

####Uber API
AutoPOOL connects to Uber's API to pull real-time price data for uberPOOL rides.

### Installation

To get the project up and running in XCode, run the following commands:

```
  git clone https://github.com/borkjt9/autopool.git autopool
  cd autopool
  pod install
```

The 'pod install' command is necessary to install the project's external library dependencies. The command installs the the libraries listed in the project's .podfile, found in the source code directory.

## Deployment

Compile and build in Xcode to install on your iOS device of choice.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
