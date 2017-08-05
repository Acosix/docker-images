#!/bin/sh

# Based on tomcat7 startup script from the APT tomcat7 package
# Since baseimage my_init system requires a non-forking script
# for our tomcat daemon this adapted script uses run instead
# of start, and does away with some of the flexibility of an
# init.d script

set -e

PATH=/bin:/usr/bin:/sbin:/usr/sbin
DESC="Tomcat servlet engine"
DEFAULT=/etc/default/tomcat7
JVM_TMP=/tmp/tomcat7-tomcat7-tmp

if [ `id -u` -ne 0 ]; then
        echo "You need root privileges to run this script"
        exit 1
fi

# Make sure tomcat is started with system locale
if [ -r /etc/default/locale ]; then
        . /etc/default/locale
        export LANG
fi

. /lib/lsb/init-functions

if [ -r /etc/default/rcS ]; then
        . /etc/default/rcS
fi


# The following variables can be overwritten in $DEFAULT

# Run Tomcat 7 as this user ID and group ID
TOMCAT7_USER=tomcat7
TOMCAT7_GROUP=tomcat7

# this is a work-around until there is a suitable runtime replacement
# for dpkg-architecture for arch:all packages
# this function sets the variable JDK_DIRS
find_jdks()
{
    for java_version in 9 8 7 6
    do
        for jvmdir in /usr/lib/jvm/java-${java_version}-openjdk-* \
                      /usr/lib/jvm/jdk-${java_version}-oracle-* \
                      /usr/lib/jvm/jre-${java_version}-oracle-*
        do
            if [ -d "${jvmdir}" -a "${jvmdir}" != "/usr/lib/jvm/java-${java_version}-openjdk-common" ]
            then
                JDK_DIRS="${JDK_DIRS} ${jvmdir}"
            fi
        done
    done

    # Add older non multi arch installations
    JDK_DIRS="${JDK_DIRS} /usr/lib/jvm/java-6-openjdk /usr/lib/jvm/java-6-sun /usr/lib/jvm/java-7-oracle"
}

# The first existing directory is used for JAVA_HOME (if JAVA_HOME is not
# defined in $DEFAULT)
JDK_DIRS="/usr/lib/jvm/default-java"
find_jdks

# Look for the right JVM to use
for jdir in $JDK_DIRS; do
    if [ -r "$jdir/bin/java" -a -z "${JAVA_HOME}" ]; then
        JAVA_HOME="$jdir"
    fi
done
export JAVA_HOME

# Directory where the Tomcat 7binary distribution resides
CATALINA_HOME=/usr/share/tomcat7

# Directory for per-instance configuration files and webapps
CATALINA_BASE=/var/lib/tomcat7

# Use the Java security manager? (yes/no)
TOMCAT7_SECURITY=no

# Default Java options
# Set java.awt.headless=true if JAVA_OPTS is not set so the
# Xalan XSL transformer can work without X11 display on JDK 1.4+
# It also looks like the default heap size of 64M is not enough for most cases
# so the maximum heap size is set to 128M
if [ -z "$JAVA_OPTS" ]; then
        JAVA_OPTS="-Djava.awt.headless=true -Xmx128M"
fi

# End of variables that can be overwritten in $DEFAULT

# overwrite settings from default file
if [ -f "$DEFAULT" ]; then
        . "$DEFAULT"
fi

if [ ! -f "$CATALINA_HOME/bin/bootstrap.jar" ]; then
        log_failure_msg "tomcat7 is not installed"
        exit 1
fi

POLICY_CACHE="$CATALINA_BASE/work/catalina.policy"

if [ -z "$CATALINA_TMPDIR" ]; then
        CATALINA_TMPDIR="$JVM_TMP"
fi

# Set the JSP compiler if set in the tomcat7.default file
if [ -n "$JSP_COMPILER" ]; then
        JAVA_OPTS="$JAVA_OPTS -Dbuild.compiler=\"$JSP_COMPILER\""
fi

SECURITY=""
if [ "$TOMCAT7_SECURITY" = "yes" ]; then
        SECURITY="-security"
fi

# Define other required variables
CATALINA_SH="$CATALINA_HOME/bin/catalina.sh"

# Look for Java Secure Sockets Extension (JSSE) JARs
if [ -z "${JSSE_HOME}" -a -r "${JAVA_HOME}/jre/lib/jsse.jar" ]; then
    JSSE_HOME="${JAVA_HOME}/jre/"
fi

if [ -z "$JAVA_HOME" ]; then
		log_failure_msg "no JDK or JRE found - please set JAVA_HOME"
		exit 1
fi

if [ ! -d "$CATALINA_BASE/conf" ]; then
		log_failure_msg "invalid CATALINA_BASE: $CATALINA_BASE"
		exit 1
fi

# Regenerate POLICY_CACHE file
umask 022
echo "// AUTO-GENERATED FILE from /etc/tomcat7/policy.d/" > "$POLICY_CACHE"
echo ""  >> "$POLICY_CACHE"
cat $CATALINA_BASE/conf/policy.d/*.policy >> "$POLICY_CACHE"

# Remove / recreate JVM_TMP directory
rm -rf "$JVM_TMP"
mkdir -p "$JVM_TMP" || {
		log_failure_msg "could not create JVM temporary directory"
		exit 1
}
chown $TOMCAT7_USER:$TOMCAT7_GROUP "$JVM_TMP"

touch $CATALINA_BASE/logs/catalina.out
chown $TOMCAT7_USER:$TOMCAT7_GROUP $CATALINA_BASE/logs/catalina.out

set -a

JAVA_HOME="${JAVA_HOME}"
CATALINA_HOME="${CATALINA_HOME}"
CATALINA_BASE="${CATALINA_BASE}"
JAVA_OPTS="${JAVA_OPTS}"
CATALINA_TMPDIR="${CATALINA_TMPDIR}"
LANG="${LANG}"
JSSE_HOME="${JSSE_HOME}"

cd $CATALINA_BASE
exec /sbin/setuser $TOMCAT7_USER $CATALINA_SH run $SECURITY >> $CATALINA_BASE/logs/catalina.out 2>&1