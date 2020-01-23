#!/usr/bin/python3

import gi
gi.require_version('Secret', '1')
from gi.repository import Secret

service = Secret.Service.get_sync(Secret.ServiceFlags.LOAD_COLLECTIONS)

collection = Secret.Collection.for_alias_sync(service, Secret.COLLECTION_DEFAULT, Secret.CollectionFlags.NONE)

if collection is None:
    Secret.Collection.create_sync(Secret.COLLECTION_DEFAULT, Secret.CollectionFlags.NONE)
    print("Created Secret.Collection {}".format(collection.get_label()))

