var SUPPORTED_PACKAGINGS = ['war', 'jar', 'zip'];

function envOr(envKey, defaultValue)
{
	var value;
	
	value = $ENV[envKey];
	if ((typeof value !== 'string' && !(value instanceof String)) || value.trim() === '')
	{
		value = defaultValue;
	}
	return value;
}

function splitMultiValuedVariable(variableValue)
{
	var values, fragments;
	
	values = [];
	fragments = variableValue.split(/,/);
	fragments.forEach(function (fragment)
	{
		if(fragment.trim() !== '')
		{
			values.push(fragment.trim());
		}		
	});
	
	return values;
}

function parseArtifactCoordinates(coordinates, defaultPackaging)
{
	var descriptor, fragments;
	
	fragments = coordinates.split(/:/);
	descriptor = {
		groupId : null,
		artifactId : null,
		packaging : null,
		version : null,
		classifier : null,
		downloadedArtifactFile : null,
		
		toString : function ()
		{
			var result;

			result = (this.groupId || '?') + ':' + (this.artifactId || '?') + ':' + (this.packaging || '?');
			if (this.classifier !== null)
			{
				result += ':' + this.classifier;
			}
			result += ':' + (this.version || '?');
			
			return result;
		}
	};
	
	fragments.forEach(function (fragment)
	{
		if (fragment.trim() !== '')
		{
			if (descriptor.groupId === null)
			{
				descriptor.groupId = fragment.trim();
			}
			else if (descriptor.artifactId === null)
			{
				descriptor.artifactId = fragment.trim();
			}
			else if (descriptor.packaging === null)
			{
				descriptor.packaging = fragment.trim();
			}
			else if (descriptor.classifier === null)
			{
				descriptor.classifier = fragment.trim();
			}
			else if (descriptor.version === null)
			{
				descriptor.version = fragment.trim();
			}
		}
	});
	
	if (descriptor.classifier === null && descriptor.packaging !== null && SUPPORTED_PACKAGINGS.indexOf(descriptor.packaging) === -1)
	{
		descriptor.classifier = descriptor.packaging;
		descriptor.packaging = defaultPackaging || null;
	}

	if (descriptor.version === null && descriptor.classifier !== null)
	{
		descriptor.version = descriptor.classifier;
		descriptor.classifier = null;
	}
	
	return descriptor;
}

function parseRepositories(repositoriesStr)
{
	var repositories = splitMultiValuedVariable(repositoriesStr);
	repositories.forEach(function (repository, idx, array)
	{
		var repositoryDescriptor, key;
		repositoryDescriptor = {
			id : repository,
			baseUrl : null,
			user : null,
			password : null
		};
		
		key = 'MAVEN_REPOSITORIES_' + repositoryDescriptor.id + '_URL';
		if ((typeof $ENV[key] === 'string' || $ENV[key] instanceof String) && $ENV[key].trim() !== '')
		{
			repositoryDescriptor.baseUrl = $ENV[key].trim();
		}
		
		key = 'MAVEN_REPOSITORIES_' + repositoryDescriptor.id + '_USER';
		if ((typeof $ENV[key] === 'string' || $ENV[key] instanceof String) && $ENV[key].trim() !== '')
		{
			repositoryDescriptor.user = $ENV[key].trim();
		}
		
		key = 'MAVEN_REPOSITORIES_' + repositoryDescriptor.id + '_PASSWORD';
		if ((typeof $ENV[key] === 'string' || $ENV[key] instanceof String) && $ENV[key].trim() !== '')
		{
			repositoryDescriptor.password = $ENV[key].trim();
		}
		
		array[idx] = repositoryDescriptor;
	});
	
	return repositories;
}

function parseArtifacts(artifactsStr)
{
	var artifacts = splitMultiValuedVariable(artifactsStr);
	artifacts.forEach(function (artifact, idx, array)
	{
		array[idx] = parseArtifactCoordinates(artifact);
		array[idx].providedOrder = idx;
	});
	return artifacts;
}

function tryDownload(url, user, password)
{
	var resultFile, fileName, jUrl, con, authString, is, os, bytes, bytesRead, totalBytesRead;

	resultFile = null;
	try
	{
		jUrl = new java.net.URL(url);
		con = jUrl.openConnection();

		if (user !== null && password !== null)
		{
			authString = user + ":" + password;
			con.setRequestProperty('Authorization', 'Basic ' + java.util.Base64.getEncoder().encodeToString(authString.bytes));
		}
		
		con.setRequestMethod("GET");
		con.setAllowUserInteraction(false);
		con.setDoInput(true);
		con.setDoOutput(false);
		
		
		fileName = url.substring(url.lastIndexOf('/') + 1);
		resultFile = $ARG.length > 0 ? new java.io.File(new java.io.File($ARG[0]), fileName) : new java.io.File(fileName);
		
		if (!resultFile.exists() || envOr('MAVEN_OVERRIDE_EXISTING_FILES', 'false') === 'true')
		{
			is = con.inputStream;
			os = new java.io.FileOutputStream(resultFile, false);
			
			bytes = new Array(8192);
			bytes = Java.to(bytes, 'byte[]');
			totalBytesRead = 0;
			
			while ((bytesRead = is.read(bytes)) !== -1)
			{
				os.write(bytes, 0, bytesRead);
				
				totalBytesRead += bytesRead;
				// log every ~5 MiB
				if (totalBytesRead % (5 * 128 * 8192) < 8192)
				{
					print('Download in progress - ' + totalBytesRead + ' bytes transferred');
				}
			}
			
			os.close();
			is.close();
			
			print('Download completed - ' + totalBytesRead + ' bytes transferred');
		}
		else
		{
			print('File already exists locally and override has not been requested via maven.overrideExistingFiles');
		}
	}
	catch (e)
	{
		if (resultFile !== null && resultFile.exists())
		{
			resultFile.delete();
		}
		
		if (os !== undefined && os !== null)
		{
			os.close();
		}
		
		if (is !== undefined && is !== null)
		{
			is.close();
		}
		
		if (!(e instanceof java.io.FileNotFoundException))
		{
			print('Error during download: ' + e.message);
		}
	}
	return resultFile;
}

function determineSnapshotVersion(baseUrl, repositoryDescriptor)
{
	var metadataFile, metadata, matches, timestamp, buildNumber;

	try
	{
		metadataFile = tryDownload(baseUrl + 'maven-metadata.xml', repositoryDescriptor.user, repositoryDescriptor.password);
		metadata = readFully(metadataFile.path);

		matches = /<timestamp>([^<]+)<\/timestamp>/.exec(metadata);
		if (matches)
		{
			timestamp = matches[1];

			matches = /<buildNumber>([^<]+)<\/buildNumber>/.exec(metadata);
			if (matches)
			{
				buildNumber = matches[1];
				return timestamp + '-' + buildNumber;
			}
		}

		metadataFile.delete();
	}
	catch(e)
	{
		if (metadataFile !== undefined)
		{
			metadataFile.delete();
		}
	}
}

function downloadArtifact(artifactDescriptor, repositoryDescriptors)
{
	repositoryDescriptors.forEach(function (repositoryDescriptor)
	{
		var expectedUrl, snapshotVersion;
		
		if (artifactDescriptor.downloadedArtifactFile === null || !artifactDescriptor.downloadedArtifactFile.exists())
		{
			if (repositoryDescriptor.baseUrl !== null)
			{
				print('Attempting to download ' + artifactDescriptor + ' from ' + repositoryDescriptor.id);
				
				expectedUrl = repositoryDescriptor.baseUrl;
				if (!expectedUrl.endsWith('/'))
				{
					expectedUrl += '/';
				}
				expectedUrl += artifactDescriptor.groupId.split(/\./).join('/');
				expectedUrl += '/';
				expectedUrl += artifactDescriptor.artifactId;
				expectedUrl += '/';
				expectedUrl += artifactDescriptor.version;
				expectedUrl += '/';
				
				if (/-SNAPSHOT$/.test(artifactDescriptor.version))
				{
					snapshotVersion = determineSnapshotVersion(expectedUrl, repositoryDescriptor);
				}
				
				expectedUrl += artifactDescriptor.artifactId;
				expectedUrl += '-';

				if (snapshotVersion !== undefined)
				{
					expectedUrl += artifactDescriptor.version.replace(/SNAPSHOT$/, snapshotVersion);
				}
				else
				{
					expectedUrl += artifactDescriptor.version;
				}
				
				if (artifactDescriptor.classifier !== null)
				{
					expectedUrl +='-';
					expectedUrl += artifactDescriptor.classifier;
				}

				if (artifactDescriptor.packaging !== null)
				{
					expectedUrl += '.';
					expectedUrl += artifactDescriptor.packaging;
					
					print('Artifact defines explicit packaging - using URL ' + expectedUrl + ' for download attempt');
					
					artifactDescriptor.downloadedArtifactFile = tryDownload(expectedUrl, repositoryDescriptor.user, repositoryDescriptor.password);
				}
				else
				{
					print('Artifact does not define explicit packaging - trying to find first available packaging from supported formats ' + JSON.stringify(SUPPORTED_PACKAGINGS));
					SUPPORTED_PACKAGINGS.forEach(function(packaging)
					{
						var url;
						if (artifactDescriptor.downloadedArtifactFile === null || !artifactDescriptor.downloadedArtifactFile.exists())
						{
							url = expectedUrl + '.' + packaging;
							print('Using URL ' + url + ' for download attempt');
							artifactDescriptor.downloadedArtifactFile = tryDownload(url, repositoryDescriptor.user, repositoryDescriptor.password);
						}
					});
				}
				
				if (artifactDescriptor.downloadedArtifactFile !== null && artifactDescriptor.downloadedArtifactFile.exists())
				{
					print('Successfully downloaded ' + artifactDescriptor + ' from ' + repositoryDescriptor.id);
				}
				else
				{
					print('Artifact ' + artifactDescriptor + ' not found on ' + repositoryDescriptor.id);;
				}
			}
		}
	});
}

function downloadArtifacts(artifactDsscriptors, repositoryDescriptors)
{
	artifactDsscriptors.forEach(function(artifactDescriptor)
	{
		if (artifactDescriptor.groupId !== null && artifactDescriptor.artifactId !== null && artifactDescriptor.version !== null)
		{
			print('Attempting to download ' + artifactDescriptor);
			downloadArtifact(artifactDescriptor, repositoryDescriptors);
		}
		else
		{
			throw new Error('Incomplete artifact descriptor: ' + JSON.stringify(artifactDescriptor));
		}
		
		if (artifactDescriptor.downloadedArtifactFile === null || !artifactDescriptor.downloadedArtifactFile.exists())
		{
			throw new Error(String(artifactDescriptor) + ' not found in any of the configured repositories');
		}
	});
}

function installArtifacts(solr4War, artifactsToInstall)
{
	artifactsToInstall.forEach(function (artifact)
	{
		var uri, zipFs;
		if (artifact.packaging === 'jar' || artifact.downloadedArtifactFile.name.endsWith('.jar'))
		{
			try
			{
				uri = new java.net.URI('jar:' + solr4War.downloadedArtifactFile.toURI());
				zipFsProps = new java.util.HashMap();
				zipFsProps.create = 'false';
				zipFsProps.encoding = 'UTF-8';
				zipFs = java.nio.file.FileSystems.newFileSystem(uri, zipFsProps);
				
				java.nio.file.Files.copy(artifact.downloadedArtifactFile.toPath(),
					zipFs.getPath('/WEB-INF', ['lib', artifact.downloadedArtifactFile.name]),
					java.nio.file.StandardCopyOption.REPLACE_EXISTING);
				zipFs.close();
			}
			catch (e)
			{
				if (zipFs !== undefined && zipFs !== null)
				{
					zipFs.close();
				}
				
				print('Error adding JAR to WAR: ' + e.message);
				if (typeof e.printStackTrace === 'function')
				{
					e.printStackTrace();
				}
				
				throw e;
			}
		}
	});
}

function main()
{
	var alfrescoVersions, alfrescoArtifacts, repositories, artifacts, requiredAlfrescoArtifacts, artifactsToInstall;
	
	alfrescoVersions = {
		solr4 : envOr('ALFRESCO_SOLR4_VERSION', '5.2.f')
	};
	
	alfrescoArtifacts = {
		solr4War : parseArtifactCoordinates(envOr('ALFRESCO_SOLR4_WAR_ARTIFACT', 'org.alfresco:alfresco-solr4:war:' + alfrescoVersions.solr4)),
		solr4ConfigZip : parseArtifactCoordinates(envOr('ALFRESCO_SOLR4_CONFIG_ZIP_ARTIFACT', 'org.alfresco:alfresco-solr4:zip:config:' + alfrescoVersions.solr4))
	};
	
	repositories = parseRepositories(envOr('MAVEN_ACTIVE_REPOSITORIES', 'acosix,alfresco,central'));
	artifacts = parseArtifacts(envOr('MAVEN_REQUIRED_ARTIFACTS', ''));
	
	requiredAlfrescoArtifacts = [alfrescoArtifacts.solr4War, alfrescoArtifacts.solr4ConfigZip];

	downloadArtifacts(requiredAlfrescoArtifacts, repositories);
	downloadArtifacts(artifacts, repositories);

	installArtifacts(alfrescoArtifacts.solr4War, artifacts);
	
	if (alfrescoArtifacts.solr4War.downloadedArtifactFile.name !== 'solr4.war')
	{
		alfrescoArtifacts.solr4War.downloadedArtifactFile.renameTo(new java.io.File(alfrescoArtifacts.solr4War.downloadedArtifactFile.parent, 'solr4.war'));
	}
	
	if (alfrescoArtifacts.solr4ConfigZip.downloadedArtifactFile.name !== 'config.zip')
	{
		alfrescoArtifacts.solr4ConfigZip.downloadedArtifactFile.renameTo(new java.io.File(alfrescoArtifacts.solr4ConfigZip.downloadedArtifactFile.parent, 'config.zip'));
	}
}

main();