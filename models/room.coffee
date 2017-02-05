Model = require "model"

Drawable = require "./drawable"
Member = require "./member"
Prop = require "./prop"

module.exports = Room = (I={}, self=Model(I)) ->
  defaults I,
    members: []
    props: []

  self.attrReader "key"
  self.include Drawable

  self.attrObservable "name"
  self.attrModels "members", Member
  self.attrModels "props", Prop

  table = db.ref("rooms")
  ref = table.child(self.key())

  subscribeToProp = (snap) ->
    stats.increment "room.subscribe-prop"

    {key} = snap
    value = snap.val()

    prop = Prop.find key
    prop.update(value)

    unless self.propByKey(key)
      self.props.push prop

  unsubscribeFromProp = ({key}) ->
    stats.increment "room.unsubscribe-prop"

    prop = self.propByKey(key)

    if prop
      self.props.remove prop
      prop.disconnect()

  subscribeToMember = ({key}) ->
    stats.increment "room.subscribe-member"

    member = Member.find key
    member.connect()

    unless self.memberByKey(key)
      self.members.push member

  unsubscribeFromMember = ({key}) ->
    stats.increment "room.unsubscribe-member"

    member = self.memberByKey(key)

    if member
      self.members.remove member
      member.disconnect()

  updateBackgroundURL = V self.imageURL

  self.extend
    addProp: ({imageURL}) ->
      ref.child("props").push
        x: (Math.random() * 960)|0
        y: (Math.random() * 540)|0
        imageURL: imageURL

    join: (accountId) ->
      # Auto-leave on disconnect
      membershipsRef.child(accountId).onDisconnect().remove()
      # Join
      membershipsRef.child(accountId).set true

    leave: (accountId) ->
      membershipsRef.child(accountId).remove()

    clearAllProps: ->
      ref.child("props").remove()

    update: (data) ->
      return unless data
      stats.increment "room.update"

      Object.keys(data).forEach (key) ->
        self[key]? data[key]

      return self

    memberByKey: (key) ->
      [member] = self.members.filter (member) ->
        member.key() is key

      return member

    propByKey: (key) ->
      [prop] = self.props.filter (prop) ->
        prop.key() is key

      return prop

    numberOfCurrentOccupants: ->
      self.members.length

    sync: ->
      ref.update
        imageURL: self.imageURL()
        name: self.name()

  # Listen for all members and props
  dataRef = db.ref("room-data/#{self.key()}")

  membershipsRef = dataRef.child("memberships")
  membershipsRef.on "child_added", subscribeToMember
  membershipsRef.on "child_removed", unsubscribeFromMember

  propsRef = dataRef.child("props")
  propsRef.on "child_added", subscribeToProp
  propsRef.on "child_removed", unsubscribeFromProp

  return self

identityMap = {}
Room.find = (id) ->
  return unless id

  identityMap[id] ?= Room
    key: id

V = (fn) ->
  (data) -> fn data.val()
